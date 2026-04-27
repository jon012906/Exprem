//
//  LiveTextDetector.swift
//  Exprem
//
//  Created by Jon on 27/04/26.
//

import Vision
import CoreVideo
import ImageIO

struct DetectedTextRegion: Equatable {
    let boundingBox: CGRect
    let text: String
    let score: Double
}

final class LiveTextDetector {
    private var isProcessing = false

    func detect(
        in pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .right,
        completion: @escaping ([DetectedTextRegion]) -> Void
    ) {
        guard !isProcessing else { return }
        isProcessing = true

        let request = VNRecognizeTextRequest { [self] req, _ in
            defer { self.isProcessing = false }
            let observations = req.results as? [VNRecognizedTextObservation] ?? []
            let regions = Array(observations
                .compactMap { Self.visibleRegion(from: $0, orientation: orientation) }
                .sorted { $0.score > $1.score }
                .prefix(16))
            completion(regions)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["id-ID", "en-US"]
        request.minimumTextHeight = 0.025

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            isProcessing = false
        }
    }

    private static func visibleRegion(
        from observation: VNRecognizedTextObservation,
        orientation: CGImagePropertyOrientation
    ) -> DetectedTextRegion? {
        guard let candidate = bestTextCandidate(for: observation) else { return nil }

        let rect = observation.boundingBox.oriented(for: orientation)
        let area = rect.width * rect.height
        guard
            area >= 0.002,
            area <= 0.5,
            rect.width >= 0.04,
            rect.height >= 0.02
        else {
            return nil
        }

        return DetectedTextRegion(
            boundingBox: rect.insetBy(dx: -0.02, dy: -0.015).clampedToUnitRect(),
            text: candidate.text,
            score: candidate.score + regionScore(for: rect)
        )
    }

    private static func bestTextCandidate(for observation: VNRecognizedTextObservation) -> (text: String, score: Double)? {
        observation.topCandidates(5)
            .map { candidate in
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return (text: text, score: textScore(text: text, confidence: candidate.confidence))
            }
            .filter { !$0.text.isEmpty }
            .max { $0.score < $1.score }
    }

    private static func textScore(text: String, confidence: VNConfidence) -> Double {
        let scalars = text.unicodeScalars
        let letterCount = scalars.filter { CharacterSet.letters.contains($0) }.count
        let digitCount = scalars.filter { CharacterSet.decimalDigits.contains($0) }.count
        let usefulCount = letterCount + digitCount
        let symbolCount = max(0, text.count - usefulCount)
        let words = normalizedWords(in: text)

        var score = Double(confidence) * 90
        score += Double(letterCount) * 2
        score += Double(digitCount)
        score -= Double(symbolCount) * 5

        if letterCount >= 3 {
            score += 8
        }

        switch words.count {
        case 1:
            score += 12
        case 2...3:
            score += 8
        case 4...:
            score -= Double(words.count - 3) * 9
        default:
            break
        }

        if (4...16).contains(usefulCount) {
            score += 8
        } else if usefulCount > 24 {
            score -= 15
        }

        if text.range(of: #"[A-Za-z]{2,}"#, options: .regularExpression) != nil {
            score += 6
        }

        if text.range(of: #"[Il1]{2,}"#, options: .regularExpression) != nil {
            score -= 10
        }

        return score
    }

    private static func regionScore(for rect: CGRect) -> Double {
        var score = min(Double(rect.area) * 100, 12)

        if rect.midY > 0.35 && rect.midY < 0.85 {
            score += 8
        } else if rect.midY < 0.2 {
            score -= 12
        }

        if rect.width > rect.height * 1.8 {
            score += 6
        } else if rect.height > rect.width {
            score -= 8
        }

        let centeredness = 1 - abs(Double(rect.midX - 0.5)) * 2
        score += max(0, centeredness) * 5

        return score
    }

    private static func normalizedWords(in text: String) -> [String] {
        text.uppercased()
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
            .joined()
            .split(separator: " ")
            .map(String.init)
    }
}

private extension CGRect {
    var area: CGFloat { width * height }

    func oriented(for orientation: CGImagePropertyOrientation) -> CGRect {
        switch orientation {
        case .right, .rightMirrored:
            return CGRect(
                x: 1 - maxY,
                y: minX,
                width: height,
                height: width
            )
        case .left, .leftMirrored:
            return CGRect(
                x: minY,
                y: 1 - maxX,
                width: height,
                height: width
            )
        case .down, .downMirrored:
            return CGRect(
                x: 1 - maxX,
                y: 1 - maxY,
                width: width,
                height: height
            )
        case .up, .upMirrored:
            return self
        @unknown default:
            return self
        }
    }

    func clampedToUnitRect() -> CGRect {
        let minX = max(0, origin.x)
        let minY = max(0, origin.y)
        let maxX = min(1, origin.x + width)
        let maxY = min(1, origin.y + height)
        guard maxX > minX, maxY > minY else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}