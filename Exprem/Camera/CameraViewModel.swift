//
//  CameraViewModel.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import AVFoundation
import UIKit
import Observation

@Observable
@MainActor

final class CameraViewModel {
    private let manager = CameraManager()
    private let textDetector = LiveTextDetector()

    var image: UIImage?
    var isCaptured: Bool = false
    var permissionDenied: Bool = false
    var errorMessage: String?

    var candidateRegions: [DetectedTextRegion] = []
    var lockedRegion: DetectedTextRegion?
    var selectedRegion: CGRect?
    var liveDetectedProductName: String?
    var liveDetectedExpiryDate: String?

    var currentStep: ScanStep = .productName
    var isProcessing: Bool = false

    enum ScanStep {
        case productName
        case expiryDate
    }

    private var lockedTextRegion: DetectedTextRegion?

    init() {
        manager.onPhotoCaptured = { [weak self] image in
            Task { @MainActor in
                self?.image = image
                self?.isCaptured = true
            }
        }
        manager.onVideoFrame = { [weak self] pixelBuffer in
            self?.textDetector.detect(in: pixelBuffer) { regions in
                Task { @MainActor in
                    self?.handleTextRegions(regions)
                }
            }
        }
    }

    private func handleTextRegions(_ regions: [DetectedTextRegion]) {
        candidateRegions = regions

        guard lockedTextRegion == nil else {
            selectedRegion = lockedRegion?.boundingBox
            return
        }

        switch currentStep {
        case .productName:
            if let first = regions.first {
                lock(first)
            }
        case .expiryDate:
            if let best = Self.bestExpiryRegion(in: regions) {
                lock(best)
            }
        }
    }

    private func lock(_ region: DetectedTextRegion?) {
        lockedTextRegion = region
        lockedRegion = region
        selectedRegion = region?.boundingBox

        switch currentStep {
        case .productName:
            liveDetectedProductName = region?.text
        case .expiryDate:
            liveDetectedExpiryDate = Self.detectedExpiryText(from: region?.text)
        }
    }

    func selectRegion(at layerPoint: CGPoint, in previewLayer: AVCaptureVideoPreviewLayer) {
        guard !candidateRegions.isEmpty else { return }

        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
        let visionPoint = CGPoint(x: devicePoint.x, y: 1.0 - devicePoint.y)

        let tappedRegion = candidateRegions.first { $0.boundingBox.contains(visionPoint) }
            ?? candidateRegions.min { r1, r2 in
                r1.boundingBox.center.distance(to: visionPoint) < r2.boundingBox.center.distance(to: visionPoint)
            }

        lockRegion(tappedRegion)
    }

    func lockRegion(_ region: DetectedTextRegion?) {
        lock(region)
    }

    func setup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            manager.configure()
            manager.start()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.permissionDenied = !granted
                }
                if granted {
                    self?.manager.configure()
                    self?.manager.start()
                }
            }

        case .restricted, .denied:
            permissionDenied = true

        @unknown default:
            permissionDenied = true
        }
    }

    func stop() {
        manager.stop()
    }

    func capture() {
        guard !permissionDenied else { return }
        manager.capturePhoto()
    }

    func retake() {
        image = nil
        isCaptured = false
    }

    func getSession() -> AVCaptureSession {
        manager.getSession()
    }

    func focusAt(point: CGPoint) {
        manager.focusAt(point: point)
    }

    private static func bestExpiryRegion(in regions: [DetectedTextRegion]) -> DetectedTextRegion? {
        regions
            .map { region in (region: region, score: expiryScore(for: region.text, region: region.boundingBox)) }
            .filter { $0.score > 0 }
            .max { $0.score < $1.score }?
            .region
    }

    private static func expiryScore(for text: String, region: CGRect) -> Double {
        let normalized = text.uppercased()
        var score = 0.0

        if detectedExpiryText(from: text) != nil {
            score += 80
        }

        if normalized.range(of: #"\d{1,2}[./\-\s]\d{1,2}[./\-\s]\d{2,4}"#, options: .regularExpression) != nil {
            score += 40
        }

        if normalized.contains("EXP") || normalized.contains("BB") || normalized.contains("BEST") {
            score += 12
        }

        if region.width > region.height {
            score += 5
        }

        return score
    }

    private static func detectedExpiryText(from text: String?) -> String? {
        guard let text, !text.isEmpty else { return nil }
        let normalized = text.uppercased().replacingOccurrences(of: "\n", with: " ")
        if let date = firstNumericDate(in: normalized, pattern: #"(?<!\d)(\d{1,2})[./\-\s](\d{1,2})[./\-\s](\d{2,4})(?!\d)"#) {
            return date
        }
        if let date = firstNumericDate(in: normalized, pattern: #"(?<!\d)(\d{1,2})[./\-\s](\d{1,2})[./\-\s](\d{2})(?=\d{3,}|\D|$)"#) {
            return date
        }
        if let date = firstCompactDate(from: normalized) {
            return date
        }
        return firstMonthNameDate(in: normalized)
    }

    private static func firstNumericDate(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges == 4,
              let dayRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let yearRange = Range(match.range(at: 3), in: text),
              let day = Int(text[dayRange]),
              let month = Int(text[monthRange]),
              var year = Int(text[yearRange]),
              (1...31).contains(day), (1...12).contains(month)
        else { return nil }
        if year < 100 { year += 2000 }
        return String(format: "%02d/%02d/%04d", day, month, year)
    }

    private static func firstCompactDate(from text: String) -> String? {
        let pattern = #"(?<!\d)(\d{6}|\d{8})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let valueRange = Range(match.range(at: 1), in: text) else { return nil }

        let value = String(text[valueRange])
        guard value.count == 6 || value.count == 8 else { return nil }

        let dayText = value.prefix(2)
        let monthText = value.dropFirst(2).prefix(2)
        let yearText = value.suffix(value.count == 6 ? 2 : 4)

        guard let day = Int(dayText), let month = Int(monthText), var year = Int(yearText),
              (1...31).contains(day), (1...12).contains(month) else { return nil }
        if year < 100 { year += 2000 }
        return String(format: "%02d/%02d/%04d", day, month, year)
    }

    private static func firstMonthNameDate(in text: String) -> String? {
        let pattern = #"(?i)(?<!\d)(\d{1,2})\s*([a-z]{3,})\.?\s*'?\s*(\d{2,4})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges == 4,
              let dayRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let yearRange = Range(match.range(at: 3), in: text),
              let day = Int(text[dayRange]),
              let month = monthNumber(for: String(text[monthRange])),
              var year = Int(text[yearRange]),
              (1...31).contains(day) else { return nil }
        if year < 100 { year += 2000 }
        return String(format: "%02d/%02d/%04d", day, month, year)
    }

    private static func monthNumber(for rawMonth: String) -> Int? {
        let key = rawMonth.uppercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let months = [
            "JAN": 1, "JANUARY": 1, "JANUARI": 1,
            "FEB": 2, "FEBRUARY": 2, "FEBRUARI": 2,
            "MAR": 3, "MARCH": 3, "MARET": 3,
            "APR": 4, "APRIL": 4,
            "MAY": 5, "MEI": 5,
            "JUN": 6, "JUNE": 6, "JUNI": 6,
            "JUL": 7, "JULY": 7, "JULI": 7,
            "AUG": 8, "AUGUST": 8, "AGU": 8, "AGUSTUS": 8,
            "SEP": 9, "SEPT": 9, "SEPTEMBER": 9,
            "OCT": 10, "OCTOBER": 10, "OKT": 10, "OKTOBER": 10,
            "NOV": 11, "NOVEMBER": 11,
            "DEC": 12, "DECEMBER": 12, "DES": 12, "DESEMBER": 12
        ]
        return months[key]
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
