//
//  ProductInfoExtracting.swift
//  Exprem
//
//  Created by Jon on 23/04/26.
//

import Foundation

protocol ProductInfoExtracting {
    func extractProductName(from ocrText: String) async throws -> String
    func extractExpiryDate(from ocrText: String) async throws -> String
}

protocol FoundationModelPrompting {
    func extract(from ocrText: String) async throws -> ProductExtractionResult
}