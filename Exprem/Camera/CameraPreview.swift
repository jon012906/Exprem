//
//  CameraPreview.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let sessionLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        sessionLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(sessionLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            sessionLayer.frame = uiView.bounds
        }
    }
}
