//
//  InputProductNameView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct InputProductNameView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var productName = ""
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
            ScanProductExpiryView(origin: origin)
        }
    }
}

#Preview {
    NavigationStack {
        InputProductNameView(origin: .onboarding)
    }
}
