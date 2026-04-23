//
//  OCRTextExtractor.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation

protocol OCRTextExtracting {
    func extractText(from imageData: Data) async throws -> String
}

enum OCRServiceError: LocalizedError {
    case invalidImage
    case noTextDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid Image."
        case .noTextDetected:
            return "Text not detected"
        }
    }
}
