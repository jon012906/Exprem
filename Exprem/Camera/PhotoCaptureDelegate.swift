//
//  PhotoCaptureDelegate.swift
//  Exprem
//
//  Created by Jon on 22/04/26.
//

import AVFoundation
import UIKit

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init (completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data:data) else{
            completion(nil)
            return
            
        }
        completion(image)
    }
}
