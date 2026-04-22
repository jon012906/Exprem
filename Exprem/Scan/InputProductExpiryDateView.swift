//
//  InputProductExpiryDateView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI

struct InputProductExpiryDateView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var selectedDate = Date()
    @State private var showAddProduct = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(.horizontal, 6)

                    Spacer()
                }
                .padding(.horizontal, 12)
            }
        }
        .navigationTitle("Input Product Expiry Date")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            showAddProduct = false
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if origin == .onboarding {
                        showAddProduct = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "arrow.forward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.appBlue)
                
            }
        }
        .navigationDestination(isPresented: $showAddProduct) {
            AddProductView()
        }
    }
}

#Preview {
    NavigationStack {
        InputProductExpiryDateView(origin: .onboarding)
    }
}
