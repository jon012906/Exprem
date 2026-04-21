//
//  CameraView.swift
//  Exprem
//
//  Created by Jon on 21/04/26.
//
import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var cameraManager: CameraManager
    var onPhotoCaptured: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showPreview = false
    @State private var capturedPhoto: UIImage?
    
    var body: some View {
        ZStack {
            if let capturedPhoto, showPreview {
                Image(uiImage: capturedPhoto)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        Button("Retake") {
                            self.capturedPhoto = nil
                            self.showPreview = false
                        }
                        Button("Use Photo") {
                            onPhotoCaptured(capturedPhoto)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                }
            } else {
                GeometryReader { _ in
                    CameraPreview(sessionLayer: cameraManager.getPreviewLayer())
                        .ignoresSafeArea()
                }
                VStack {
                    Spacer()
                    Button(action: {
                        cameraManager.takePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear { cameraManager.startSession() }
        .onDisappear { cameraManager.stopSession() }
        .onChange(of: cameraManager.capturedImage) { image in   
            if let img = image {
                self.capturedPhoto = img
                self.showPreview = true
            }
        }
    }
}
