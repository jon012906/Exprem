//
//  ScanProductNameView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//
import SwiftUI

struct ScanProductNameView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var showManualInput = false
    @State private var showScanExpiry = false

    var body: some View {
        ZStack {

            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.appSurfaceMuted)

                    VStack(spacing: 26) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 190, weight: .regular))
                            .foregroundStyle(theme.appBlue)

                        Image(systemName: "doc.fill")
                            .font(.system(size: 80, weight: .regular))
                            .foregroundStyle(theme.appBlue)
                            .offset(y: -128)

                        Spacer()

                        Button("Type your product name") {
                            showManualInput = true
                        }
                        .buttonStyle(.plain)
                        .font(.headline)
                        .foregroundStyle(theme.appBlue)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                captureBar {
                    showScanExpiry = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .navigationTitle("Scan Product Name")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showManualInput) {
            InputProductNameView(origin: origin)
        }
        .navigationDestination(isPresented: $showScanExpiry) {
            ScanProductExpiryView(origin: origin)
        }
    }

    private func captureBar(action: @escaping () -> Void) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)

                    Circle()
                        .stroke(theme.appBorder, lineWidth: 3)
                        .frame(width: 74, height: 74)

                    Image(systemName: "camera.fill")
                        .font(.title3)
                        .foregroundStyle(theme.appTextSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 108)
        .padding(.top, 10)
    }
}

#Preview {
    NavigationStack {
        ScanProductNameView(origin: .onboarding)
    }
}
