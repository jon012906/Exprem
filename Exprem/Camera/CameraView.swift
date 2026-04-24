////    THIS ONLY FOR BENCHMARKING
////  CameraView.swift
////  Exprem
////
////  Created by Jon on 22/04/26.
////
//
//import SwiftUI
//import AVFoundation
//import UIKit
//import Observation
//
//struct CameraView: View {
//    @State private var viewModel = CameraViewModel()
//
//    var body: some View {
//        ZStack {
//            CameraPreview(session: viewModel.getSession())
//                .ignoresSafeArea()
//
//            VStack {
//                Spacer()
//
//                Button(action: {
//                    viewModel.capture()
//                }) {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 70, height: 70)
//                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
//                }
//                .padding(.bottom, 30)
//            }
//        }
//        .onAppear {
//            viewModel.setup()
//        }
//        .onDisappear {
//            viewModel.stop()
//        }
//        .fullScreenCover(isPresented: $viewModel.isCaptured) {
//            if let image = viewModel.image {
//                CapturedImageView(viewModel: viewModel, image: image)
//            }
//        }
//    }
//}
//
//struct CapturedImageView: View {
//    @Bindable var viewModel: CameraViewModel
//    let image: UIImage
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        VStack {
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .ignoresSafeArea()
//                
//            Button("Use Photo"){
//                viewModel.retake()
//                dismiss()
//            }
//            .padding()
//        }
//    }
//    
//
//
//}
