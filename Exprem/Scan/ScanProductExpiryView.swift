//
//  ScanProductExpiryView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import UIKit

struct ScanProductExpiryView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var cameraVM = CameraViewModel()
    @State private var showManualExpiry = false
    @State private var showAddProduct = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.appSurfaceMuted)

                    CameraPreview(session: cameraVM.getSession())
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    scanBorderOverlay

                    if cameraVM.permissionDenied {
                        permissionOverlay
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    showManualExpiry = true
                } label: {
                    Label("Type your product expiry date", systemImage: "keyboard")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.appBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(theme.appBorder.opacity(0.9), lineWidth: 0.8)
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
                .padding(.horizontal, 8)

                captureBar {
                    cameraVM.capture()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .onAppear {
            cameraVM.setup()
        }
        .onDisappear {
            cameraVM.stop()
        }
        .onChange(of: cameraVM.isCaptured) { isCaptured in
            guard isCaptured else { return }
            cameraVM.retake()
            if origin == .onboarding {
                showAddProduct = true
            } else {
                dismiss()
            }
        }
        .navigationTitle("Scan Product Expiry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showManualExpiry) {
            InputProductExpiryDateView(origin: origin)
        }
        .navigationDestination(isPresented: $showAddProduct) {
            AddProductView()
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
            .disabled(cameraVM.permissionDenied)
            .opacity(cameraVM.permissionDenied ? 0.5 : 1)
        }
        .frame(height: 108)
        .padding(.top, 10)
    }

    private var scanBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(theme.appBlue.opacity(0.95), lineWidth: 5)
            .frame(width: 220, height: 220)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
                    .padding(8)
            }
    }

    private var permissionOverlay: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.title3)
                .foregroundStyle(theme.appBlue)

            Text("Allow camera access to scan.")
                .font(.subheadline)
                .foregroundStyle(theme.appTextSecondary)

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.appBlue)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 26)
    }
}

#Preview {
    NavigationStack {
        ScanProductExpiryView(origin: .onboarding)
    }
}
