//
//  ScanRegion.swift
//  Exprem
//

import CoreGraphics

enum ScanRegion {
    static let normalizedRect = CGRect(x: 0.24, y: 0.35, width: 0.52, height: 0.30)

    static func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: normalizedRect.origin.x * size.width,
            y: normalizedRect.origin.y * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
    }
}
