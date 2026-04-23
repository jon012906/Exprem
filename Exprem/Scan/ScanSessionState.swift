//
//  ScanSessionState.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation
import UIKit

@MainActor
final class ScanSessionState: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var cachedOCRText: String?
    @Published var isProcessingOCR: Bool = false
    @Published var lastOCRError: String?

    private let ocrService = VisionOCRService()
    private let infoExtractor = FoundationProductInfoExtractor()

    private var thumbnailDataCache: Data?

    func storeCapturedImage(_ image: UIImage) {
        originalImage = image
    }

    func processAndExtractName() async -> String? {
        guard let image = originalImage,
              let imageData = image.jpegData(compressionQuality: 1.0) else {
            lastOCRError = "No image to process"
            return nil
        }

        isProcessingOCR = true
        lastOCRError = nil

        do {
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
        guard let text = cachedOCRText else {
            if let image = originalImage,
               let imageData = image.jpegData(compressionQuality: 1.0) {
                isProcessingOCR = true
                lastOCRError = nil
                do {
                    let text = try await ocrService.extractText(from: imageData)
                    cachedOCRText = text

                    let expiryDate = try await infoExtractor.extractExpiryDate(from: text)

                    if thumbnailDataCache == nil, let image = originalImage {
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
            return nil
        }

        isProcessingOCR = true
        do {
            let expiryDate = try await infoExtractor.extractExpiryDate(from: text)

            if thumbnailDataCache == nil, let image = originalImage {
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