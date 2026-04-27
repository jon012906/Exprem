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
    @Binding var draft: ProductDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var session = ScanSessionState()
    @State private var cameraVM = CameraViewModel()
    @State private var showManualExpiry = false
    @State private var showAddProduct = false
    @State private var showNotDetectedAlert = false
    @State private var detectedExpiry: Date? = nil
    @State private var focusIndicatorPoint: CGPoint?
    @State private var focusPulse: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.appSurfaceMuted)

                    CameraPreview(session: cameraVM.getSession()) { normalizedPoint, viewPoint in
                        cameraVM.focusAt(point: normalizedPoint)
                        focusIndicatorPoint = viewPoint
                        focusPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                            focusIndicatorPoint = nil
                        }
                    }
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .contentShape(Rectangle())

                    livePreviewOverlay

                    if let point = focusIndicatorPoint {
                        focusIndicator(at: point)
                    }

                    scanBorderOverlay

                    if cameraVM.permissionDenied {
                        permissionOverlay
                    }

                    if session.isProcessingOCR {
                        processingOverlay
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: min(UIScreen.main.bounds.height * 0.56, 420))

                Button {
                    showManualExpiry = true
                } label: {
                    Label("Input your product expiry date", systemImage: "calendar.badge.clock")
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
        .onChange(of: cameraVM.livePreviewText) { _ in
            guard focusIndicatorPoint != nil else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                focusPulse.toggle()
            }
        }
        .onChange(of: cameraVM.isCaptured) { isCaptured in
            guard isCaptured else { return }
            guard let image = cameraVM.image else { return }
            session.storeCapturedImage(image)

            Task {
                defer { cameraVM.retake() }
                if let expiryDate = await session.extractExpiryDate() {
                    await MainActor.run {
                        detectedExpiry = expiryDate
                    }
                } else {
                    await MainActor.run {
                        showNotDetectedAlert = true
                    }
                }
            }
        }
        .navigationTitle("Scan Product Expiry")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Expiry Date Not Detected", isPresented: $showNotDetectedAlert) {
            Button("Try Again", role: .cancel) { }
            Button("Input Manual") { showManualExpiry = true }
        } message: {
            Text("Please try again or input manually.")
        }
        .alert("Scan Result", isPresented: Binding(
            get: { detectedExpiry != nil },
            set: { if !$0 { detectedExpiry = nil } }
        )) {
            Button("Retake", role: .cancel) {
                detectedExpiry = nil
            }
            Button("Continue") {
                guard let expiry = detectedExpiry else { return }
                draft.expiryDate = expiry
                if draft.thumbnailData == nil {
                    draft.thumbnailData = session.getThumbnailData()
                }
                session.clearCachedText()
                detectedExpiry = nil
                if origin == .onboarding {
                    showAddProduct = true
                } else {
                    dismiss()
                }
            }
        } message: {
            if let expiry = detectedExpiry {
                Text("Expiry date detected:\n\(expiry.formatted(date: .long, time: .omitted))")
            }
        }
        .navigationDestination(isPresented: $showManualExpiry) {
            InputProductExpiryDateView(origin: origin, draft: $draft)
        }
        .navigationDestination(isPresented: $showAddProduct) {
            AddProductView(draft: draft)
        }
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

    private var livePreviewOverlay: some View {
        VStack {
            if !cameraVM.livePreviewText.isEmpty {
                Text(cameraVM.livePreviewText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.appTextPrimary)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.appBorder.opacity(0.85), lineWidth: 0.8)
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.22), value: cameraVM.livePreviewText)
    }

    private func focusIndicator(at point: CGPoint) -> some View {
        Circle()
            .stroke(theme.appBlue.opacity(0.95), lineWidth: 2.2)
            .frame(width: 72, height: 72)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.6), lineWidth: 1)
                    .padding(8)
            }
            .scaleEffect(focusPulse ? 1 : 0.82)
            .opacity(focusPulse ? 0.2 : 1)
            .position(point)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.55), value: focusPulse)
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
        ScanProductExpiryView(origin: .onboarding, draft: .constant(ProductDraft()))
    }
}
