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
    var focusPosition: CGPoint?
    var focusSize: CGFloat = 150

    func storeCapturedImage(_ image: UIImage) {
        originalImage = image
    }

    func storeFocusPosition(_ position: CGPoint?) {
        focusPosition = position
    }

    func processAndExtractName() async -> String? {
        guard let image = originalImage else {
            lastOCRError = "No image to process"
            return nil
        }

        isProcessingOCR = true
        lastOCRError = nil

        do {
            let imageData: Data

            if let focus = focusPosition {
                if let cropped = cropImage(image, toRectAt: focus) {
                    imageData = cropped.jpegData(compressionQuality: 1.0) ?? image.jpegData(compressionQuality: 1.0)!
                } else {
                    imageData = image.jpegData(compressionQuality: 1.0)!
                }
            } else {
                imageData = image.jpegData(compressionQuality: 1.0)!
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
            let imageData: Data

            if let focus = focusPosition {
                if let cropped = cropImage(image, toRectAt: focus) {
                    imageData = cropped.jpegData(compressionQuality: 1.0) ?? image.jpegData(compressionQuality: 1.0)!
                } else {
                    imageData = image.jpegData(compressionQuality: 1.0)!
                }
            } else {
                imageData = image.jpegData(compressionQuality: 1.0)!
            }

            let text = try await ocrService.extractText(from: imageData)
            cachedOCRText = text

            let expiryDate = try await infoExtractor.extractExpiryDate(from: text)

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

    private func cropImage(_ image: UIImage, toRectAt focus: CGPoint) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let halfSize = focusSize / 2
        let x = focus.x - halfSize
        let y = focus.y - halfSize

        let cropRect = CGRect(x: x, y: y, width: focusSize, height: focusSize)

        guard let cropped = cgImage.cropping(to: cropRect) else { return nil }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
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
}