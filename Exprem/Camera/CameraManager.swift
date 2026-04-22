//
//  CameraManager.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import AVFoundation
import UIKit

final class CameraManager {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    /// retain delegates to prevent them from being deallocated before the capture process completes
    private var inFlightDelegates: [Int64: PhotoCaptureDelegate] = [:]
    
    private var isConfigured = false
    
    var onPhotoCaptured: ((UIImage) -> Void)?
    
    func configure() {
        sessionQueue.async {
            guard !self.isConfigured else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            defer {self.session.commitConfiguration()}
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input)
            else {
                print("Camera input setup failed")
                return
            }
            
            self.session.addInput(input)
            
            // add photo output
            guard self.session.canAddOutput(self.photoOutput) else {
                print("Photo output setup failed")
                return
            }
            
            self.session.addOutput(self.photoOutput)
            
            self.isConfigured = true
        }
    }
        
    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
        
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
            
    func capturePhoto() {
        sessionQueue.async {
            guard self.isConfigured, self.session.isRunning else {
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            let id = settings.uniqueID

            let delegate = PhotoCaptureDelegate { [weak self] image in
                DispatchQueue.main.async {
                    if let image = image {
                        self?.onPhotoCaptured?(image)
                    }
                    self?.inFlightDelegates.removeValue(forKey: id)
                }
            }

            self.inFlightDelegates[id] = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    func getSession() -> AVCaptureSession {
        session
    }
    
}
