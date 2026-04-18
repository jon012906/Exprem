//
//  ProdictSectionView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct ProductSectionView: View {
    var title: String
    var products: [ProductItem]
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Section Title
            Text("\(title) (\(products.count))")
                .font(.subheadline)
                .foregroundColor(theme.appTextSecondary)
                .padding(.horizontal)

            // Product List
            VStack(spacing: 10) {
                ForEach(products) { product in
                    ProductCardView(item: product) { _ in }
                }
            }
            .padding(.horizontal)
        }
    }
}
