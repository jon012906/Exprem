//
//  ScanProductExpiryView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct ScanProductExpiryView: View {
    let origin: ScanFlowOrigin

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var cameraManager = CameraManager()
    @State private var showManualExpiry = false
    @State private var showAddProduct = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.appSurfaceMuted)

                    CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    if cameraManager.authorizationStatus != .authorized {
                        permissionOverlay
                    } else if let error = cameraManager.errorMessage {
                        infoOverlay(message: error, showSettings: false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    showManualExpiry = true
                } label: {
                    Label("Type your product expiry date", systemImage: "calender")
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
                    cameraManager.takePhoto()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .onAppear {
            cameraManager.requestAccessIfNeeded()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { image in
            guard image != nil else { return }
            cameraManager.clearCapturedImage()
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
            .disabled(cameraManager.authorizationStatus != .authorized)
            .opacity(cameraManager.authorizationStatus == .authorized ? 1 : 0.5)
        }
        .frame(height: 108)
        .padding(.top, 10)
    }

    private var permissionOverlay: some View {
        infoOverlay(
            message: "Allow camera access to scan expiry dates.",
            showSettings: cameraManager.authorizationStatus == .denied || cameraManager.authorizationStatus == .restricted
        )
    }

    private func infoOverlay(message: String, showSettings: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.title)
                .foregroundStyle(theme.appBlue)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.appTextSecondary)
                .multilineTextAlignment(.center)

            if showSettings {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.appBlue)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 28)
    }
}

#Preview {
    NavigationStack {
        ScanProductExpiryView(origin: .onboarding)
    }
}
