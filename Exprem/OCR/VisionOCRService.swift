//
//  VisionOCRService.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation
import UIKit
import Vision
import CoreImage

final class VisionOCRService: OCRTextExtracting {
    private let ciContext = CIContext()

    func extractText(from imageData: Data) async throws -> String {
        guard let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage else {
            throw OCRServiceError.invalidImage
        }

        let processedImage = enhancedForOCR(cgImage)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                guard !observations.isEmpty else {
                    continuation.resume(throwing: OCRServiceError.noTextDetected)
                    return
                }

                // #1: Rank by area × confidence — better proxy for visual dominance than height alone.
                let prominentTexts = Set(
                    observations
                        .sorted {
                            let scoreA = ($0.boundingBox.height * $0.boundingBox.width) * Double($0.topCandidates(1).first?.confidence ?? 0)
                            let scoreB = ($1.boundingBox.height * $1.boundingBox.width) * Double($1.topCandidates(1).first?.confidence ?? 0)
                            return scoreA > scoreB
                        }
                        .prefix(3)
                        .compactMap { $0.topCandidates(1).first?.string }
                )

                // #2: Split by y-position. Vision y: 0 = bottom, 1 = top of image.
                // Brand names appear in top half; expiry dates in bottom half.
                func formatObservations(_ obs: [VNRecognizedTextObservation]) -> String {
                    obs.compactMap { o -> String? in
                        guard let text = o.topCandidates(1).first?.string else { return nil }
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return nil }
                        return prominentTexts.contains(text) ? "[MENONJOL] \(trimmed)" : trimmed
                    }.joined(separator: "\n")
                }

                let topSection = formatObservations(observations.filter { $0.boundingBox.origin.y > 0.5 })
                let bottomSection = formatObservations(observations.filter { $0.boundingBox.origin.y <= 0.5 })

                continuation.resume(returning: topSection + "\n[---]\n" + bottomSection)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["id-ID", "en-US"]

            let handler = VNImageRequestHandler(cgImage: processedImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Converts to grayscale and boosts contrast — improves OCR on dark or low-contrast packaging.
    private func enhancedForOCR(_ cgImage: CGImage) -> CGImage {
        let ci = CIImage(cgImage: cgImage)

        guard
            let grayscale = CIFilter(name: "CIColorControls", parameters: [
                kCIInputImageKey: ci,
                kCIInputSaturationKey: 0.0,  // grayscale
                kCIInputContrastKey: 1.4,    // sharpen contrast
                kCIInputBrightnessKey: 0.05  // slight lift for dark images
            ])?.outputImage,
            let result = ciContext.createCGImage(grayscale, from: grayscale.extent)
        else {
            return cgImage
        }

        return result
    }
}
