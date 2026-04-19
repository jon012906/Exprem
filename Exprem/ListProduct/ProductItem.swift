//
//  ProductItem.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import Foundation

struct ProductItem: Identifiable {
    let id = UUID()
    let name: String
    let expiryDate: Date
//    let thumbnail: Data
}
