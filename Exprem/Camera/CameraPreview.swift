//
//  CameraPreview.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    var lockedRegion: DetectedTextRegion?
    var allCandidates: [DetectedTextRegion] = []
    var onRegionTapped: ((DetectedTextRegion) -> Void)?
    var onTap: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onTap = { point in
            context.coordinator.handleTap(at: point)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.updateRegions(lockedRegion, allCandidates: allCandidates)
        context.coordinator.previewLayer = uiView.previewLayer
    }

    class Coordinator {
        var parent: CameraPreview
        var lockedRegion: DetectedTextRegion?
        var allCandidates: [DetectedTextRegion] = []
        weak var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        func updateRegions(_ region: DetectedTextRegion?, allCandidates: [DetectedTextRegion]) {
            self.lockedRegion = region
            self.allCandidates = allCandidates
        }

        func handleTap(at point: CGPoint) {
            guard let layer = previewLayer else { return }

            let devicePoint = layer.captureDevicePointConverted(fromLayerPoint: point)
            let visionPoint = CGPoint(x: devicePoint.x, y: 1.0 - devicePoint.y)

            if let tapped = allCandidates.first(where: { $0.boundingBox.contains(visionPoint) }) {
                parent.onRegionTapped?(tapped)
            } else {
                parent.onTap?(point)
            }
        }
    }
}

final class PreviewView: UIView {
    var onTap: ((CGPoint) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        if hit == self {
            onTap?(point)
            return nil
        }
        return hit
    }
}

struct SingleRegionOverlay: View {
    let region: DetectedTextRegion?
    let frameSize: CGSize
    let tintColor: Color

    var body: some View {
        if let region {
            GeometryReader { geometry in
                let rect = convertRect(region.boundingBox, in: geometry.size)
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(tintColor, lineWidth: 2.5)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    Text(region.text)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(tintColor.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(x: rect.midX, y: rect.minY - 14)
                }
            }
        }
    }

    private func convertRect(_ normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let x = normalizedRect.origin.x * size.width
        let y = (1 - normalizedRect.origin.y - normalizedRect.height) * size.height
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct RegionCandidatesOverlay: View {
    let candidates: [DetectedTextRegion]
    let frameSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(candidates.enumerated()), id: \.offset) { _, region in
                let rect = convertRect(region.boundingBox, in: geometry.size)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    private func convertRect(_ normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let x = normalizedRect.origin.x * size.width
        let y = (1 - normalizedRect.origin.y - normalizedRect.height) * size.height
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}