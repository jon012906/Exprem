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
    var onTapToFocus: ((CGPoint, CGPoint) -> Void)? = nil
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onTapToFocus = onTapToFocus
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.onTapToFocus = onTapToFocus
    }
}

final class PreviewView: UIView {
    var onTapToFocus: ((CGPoint, CGPoint) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let viewPoint = recognizer.location(in: self)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
        onTapToFocus?(devicePoint, viewPoint)
    }
        
}
