//
//  ScanProductNameView.swift
//  Exprem
//
//  Created by Jon on 12/04/26.
//

import SwiftUI
import UIKit

struct ScanProductNameView: View {
    let origin: ScanFlowOrigin
    @Binding var draft: ProductDraft

    @Environment(\.appTheme) private var theme
    @State private var cameraVM = CameraViewModel()
    @State private var showManualInput = false
    @State private var showScanExpiry = false
    @State private var showNotDetectedAlert = false
    @State private var detectedName: String? = nil
    @State private var isProcessingCapture = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.appSurfaceMuted)

                    CameraPreview(
                        session: cameraVM.getSession(),
                        lockedRegion: cameraVM.lockedRegion,
                        allCandidates: cameraVM.candidateRegions,
                        onRegionTapped: { region in
                            cameraVM.lockRegion(region)
                        },
                        onTap: { point in
                            cameraVM.focusAt(point: point)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        cameraVM.focusAt(point: location)
                    }

                    scanBorderOverlay

                    if cameraVM.permissionDenied {
                        permissionOverlay
                    }

                    if isProcessingCapture {
                        processingOverlay
                    }
                }
                .frame(height: 400)

                liveDetectedPanel

                Button {
                    showManualInput = true
                } label: {
                    Label("Type your product name", systemImage: "keyboard")
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
                    isProcessingCapture = true
                    cameraVM.capture()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .onAppear {
            cameraVM.currentStep = .productName
            cameraVM.setup()
        }
        .onDisappear {
            cameraVM.stop()
        }
        .onChange(of: cameraVM.isCaptured) { isCaptured in
            guard isCaptured else { return }
            guard let image = cameraVM.image else { return }
            isProcessingCapture = false

            Task {
                defer { cameraVM.retake() }
                let ocrService = VisionOCRService()
                let extractor = FoundationProductInfoExtractor()

                if let imageData = image.jpegData(compressionQuality: 1.0),
                   let text = try? await ocrService.extractText(from: imageData),
                   let name = try? await extractor.extractProductName(from: text) {
                    await MainActor.run {
                        detectedName = name
                    }
                } else {
                    await MainActor.run {
                        showNotDetectedAlert = true
                    }
                }
            }
        }
        .navigationTitle("Scan Product Name")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Product Name Not Detected", isPresented: $showNotDetectedAlert) {
            Button("Try Again", role: .cancel) { }
            Button("Input Manual") { showManualInput = true }
        } message: {
            Text("Please try again or input manually.")
        }
        .alert("Scan Result", isPresented: Binding(
            get: { detectedName != nil },
            set: { if !$0 { detectedName = nil } }
        )) {
            Button("Retake", role: .cancel) {
                detectedName = nil
            }
            Button("Continue") {
                if let name = detectedName {
                    draft.nameProduct = name
                    detectedName = nil
                    showScanExpiry = true
                }
            }
        } message: {
            Text("Product name:\n\"\(detectedName ?? "")\"")
        }
        .navigationDestination(isPresented: $showManualInput) {
            InputProductNameView(origin: origin, draft: $draft)
        }
        .navigationDestination(isPresented: $showScanExpiry) {
            ScanProductExpiryView(origin: origin, draft: $draft)
        }
    }

    private var liveDetectedPanel: some View {
        VStack(spacing: 8) {
            if let name = cameraVM.liveDetectedProductName {
                Text(name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            } else {
                Text("Point camera at product name")
                    .font(.subheadline)
                    .foregroundStyle(theme.appTextSecondary)
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    @ViewBuilder
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

    private var processingOverlay: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(theme.appBlue)

            Text("Scanning...")
                .font(.subheadline)
                .foregroundStyle(theme.appTextSecondary)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ScanProductNameView(origin: .onboarding, draft: .constant(ProductDraft()))
    }
}