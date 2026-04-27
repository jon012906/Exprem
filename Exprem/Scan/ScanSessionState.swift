//
//  ScanSessionState.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation
import UIKit

@MainActor
@Observable
final class ScanSessionState {
    var originalImage: UIImage?
    var cachedOCRText: String?
    var isProcessingOCR: Bool = false
    var lastOCRError: String?

    private let ocrService = VisionOCRService()
    private let infoExtractor = FoundationProductInfoExtractor()

    private var thumbnailDataCache: Data?

    func storeCapturedImage(_ image: UIImage) {
        originalImage = image
    }

    func processAndExtractName() async -> String? {
        guard let image = originalImage else {
            lastOCRError = "No image to process"
            return nil
        }

        isProcessingOCR = true
        lastOCRError = nil

        do {
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                throw NSError(domain: "ScanSessionState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            }

            let text = try await ocrService.extractText(from: imageData)
            cachedOCRText = text

            let name = try await infoExtractor.extractProductName(from: text)

            thumbnailDataCache = makeThumbnailData(from: image)

            releaseOriginalImage()

            isProcessingOCR = false
            return name

        } catch {
            lastOCRError = error.localizedDescription
            isProcessingOCR = false
            return nil
        }
    }

    func extractExpiryDate() async -> Date? {
        guard let image = originalImage else {
            lastOCRError = "No image to process"
            return nil
        }

        isProcessingOCR = true
        lastOCRError = nil

        do {
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                throw NSError(domain: "ScanSessionState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            }

            let text = try await ocrService.extractText(from: imageData)
            cachedOCRText = text

            let dateString = try await infoExtractor.extractExpiryDate(from: text)
            let expiryDate = parseDate(from: dateString)

            if thumbnailDataCache == nil {
                thumbnailDataCache = makeThumbnailData(from: image)
            }

            releaseOriginalImage()
            clearCachedText()

            isProcessingOCR = false
            return expiryDate
        } catch {
            lastOCRError = error.localizedDescription
            isProcessingOCR = false
            return nil
        }
    }

    func getThumbnailData() -> Data? {
        return thumbnailDataCache
    }

    func releaseOriginalImage() {
        originalImage = nil
    }

    func clearCachedText() {
        cachedOCRText = nil
        thumbnailDataCache = nil
    }

    func cleanup() {
        releaseOriginalImage()
        clearCachedText()
        lastOCRError = nil
    }

    private func makeThumbnailData(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 300

        var targetSize = image.size
        if targetSize.width > maxDimension || targetSize.height > maxDimension {
            let ratio = min(maxDimension / targetSize.width, maxDimension / targetSize.height)
            targetSize = CGSize(width: targetSize.width * ratio, height: targetSize.height * ratio)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized.jpegData(compressionQuality: 0.72)
    }

    private func parseDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: string)
    }
}