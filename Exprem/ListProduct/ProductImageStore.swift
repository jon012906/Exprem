//
// ProductDraft.swift
// Exprem
//
// Created by Jon on 22/04/26.

import Foundation
import UIKit

enum ProductImageStore {
    private static let directoryName = "ProductThumbnails"

    static func saveThumbnail(from imageData: Data, compressionQuality: CGFloat = 0.72) -> String? {
        guard let image = UIImage(data: imageData),
              let compressed = image.jpegData(compressionQuality: compressionQuality)
        else {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"
        let url = thumbnailsDirectoryURL().appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(
                at: thumbnailsDirectoryURL(),
                withIntermediateDirectories: true
            )
            try compressed.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func loadImage(filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = thumbnailsDirectoryURL().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func deleteImage(filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        let url = thumbnailsDirectoryURL().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    private static func thumbnailsDirectoryURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }
}
