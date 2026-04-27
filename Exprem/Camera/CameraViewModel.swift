//
//  CameraViewModel.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import AVFoundation
import UIKit
import Observation

@Observable
@MainActor

final class CameraViewModel {
    private let manager = CameraManager()
    var image: UIImage?
    var isCaptured: Bool = false
    var permissionDenied: Bool = false
    var errorMessage: String?
    var livePreviewText: String = ""
    
    init(){
        manager.onPhotoCaptured = { [weak self] image in
            Task { @MainActor in
                self?.image = image
                self?.isCaptured = true
            }
        }

        manager.onLiveTextPreview = { [weak self] text in
            Task { @MainActor in
                self?.livePreviewText = text
            }
        }
    }
    
    func setup(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            manager.configure()
            manager.start()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.permissionDenied = !granted
                }
                if granted {
                    self?.manager.configure()
                    self?.manager.start()
                }
            }
            
        case .restricted, .denied:
            permissionDenied = true
            
        @unknown default:
            permissionDenied = true
            
        }
    }
    func stop(){
        manager.stop()
    }
    
    func capture() {
        guard !permissionDenied else { return }
        manager.capturePhoto()
    }

    func retake() {
        image = nil
        isCaptured = false
    }

    func clearLivePreviewText() {
        livePreviewText = ""
    }
    
    func getSession() -> AVCaptureSession {
        manager.getSession()
    }

    func focusAt(point: CGPoint) {
        manager.focusAt(point: point)
    }
}
