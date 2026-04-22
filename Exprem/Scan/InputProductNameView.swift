//
//  InputProductNameView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct InputProductNameView: View {
    let origin: ScanFlowOrigin
    @Binding var draft: ProductDraft

    @Environment(\.appTheme) private var theme
    @State private var showScanExpiry = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Product Name", text: $productName)
                        .font(.body)
                        .padding(.top, 4)

                    Divider()

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Input Product Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    draft.nameProduct = productName.trimmingCharacters(in: .whitespacesAndNewlines)
                    showScanExpiry = true
                } label: {
                    Image(systemName: "arrow.forward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.appBlue)
                  
            }
        }
        .navigationDestination(isPresented: $showScanExpiry) {
            ScanProductExpiryView(origin: origin, draft: $draft)
        }
        .onAppear {
            productName = draft.nameProduct
        }
    }

    @State private var productName = ""
}

#Preview {
    NavigationStack {
        InputProductNameView(origin: .onboarding, draft: .constant(ProductDraft()))
    }
}
