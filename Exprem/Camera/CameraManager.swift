//
//  CameraManager.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//

import AVFoundation
import UIKit
import Vision

final class CameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    /// retain delegates to prevent them from being deallocated before the capture process completes
    private var inFlightDelegates: [Int64: PhotoCaptureDelegate] = [:]
    
    private var isConfigured = false
    private var isPerformingLiveOCR = false
    private var activeROIRect: CGRect?
    private var lastLiveOCRTime: CFAbsoluteTime = 0
    private let liveOCRInterval: CFAbsoluteTime = 0.35
    
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onLiveTextPreview: ((String) -> Void)?
    
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

            guard self.session.canAddOutput(self.videoOutput) else {
                print("Video output setup failed")
                return
            }

            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.session.addOutput(self.videoOutput)

            if let connection = self.videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
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
            self.isPerformingLiveOCR = false
            self.activeROIRect = nil
            DispatchQueue.main.async {
                self.onLiveTextPreview?("")
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

    func focusAt(point: CGPoint) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

        sessionQueue.async {
            self.activeROIRect = self.makeROIRect(around: point)
            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()
            } catch {
                print("Focus failed: \(error)")
            }
        }
    }

    private func makeROIRect(around point: CGPoint) -> CGRect {
        let width: CGFloat = 0.36
        let height: CGFloat = 0.22
        let x = max(0, min(1 - width, point.x - (width / 2)))
        let y = max(0, min(1 - height, point.y - (height / 2)))
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func recognizeTopText(in pixelBuffer: CVPixelBuffer, regionOfInterest: CGRect) -> String {
        let visionROI = CGRect(
            x: regionOfInterest.origin.x,
            y: 1 - regionOfInterest.origin.y - regionOfInterest.height,
            width: regionOfInterest.width,
            height: regionOfInterest.height
        )

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["id-ID", "en-US"]
        request.regionOfInterest = visionROI

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let candidates = observations.compactMap { observation -> (text: String, confidence: Float)? in
                guard let top = observation.topCandidates(1).first else { return nil }
                let cleaned = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard cleaned.count >= 2 else { return nil }
                return (cleaned, top.confidence)
            }

            return candidates
                .sorted { $0.confidence > $1.confidence }
                .first?
                .text ?? ""
        } catch {
            return ""
        }
    }
    
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard output === videoOutput else { return }
        guard session.isRunning else { return }
        guard let roi = activeROIRect else { return }
        guard !isPerformingLiveOCR else { return }

        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastLiveOCRTime >= liveOCRInterval else { return }
        lastLiveOCRTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        isPerformingLiveOCR = true
        let text = recognizeTopText(in: pixelBuffer, regionOfInterest: roi)
        isPerformingLiveOCR = false

        DispatchQueue.main.async {
            self.onLiveTextPreview?(text)
        }
    }
}
