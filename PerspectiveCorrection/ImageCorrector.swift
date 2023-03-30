//
//  ImageCorrector.swift
//  PerspectiveCorrection
//
//  Created by 清浦 駿 on 2023/03/29.
//

import UIKit

struct ImageCorrector {
    static func getPerspectiveCorrectedImage(image: CIImage, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) async -> CIImage {
        let parameters: [String: Any] = [
            "inputCrop": 1,
            "inputTopLeft": topLeft.toVector(from: image),
            "inputTopRight": topRight.toVector(from: image),
            "inputBottomLeft": bottomLeft.toVector(from: image),
            "inputBottomRight": bottomRight.toVector(from: image)
        ]

        return image.applyingFilter("CIPerspectiveCorrection", parameters: parameters)
    }
}

extension CGPoint {
    func toVector(from image: CIImage) -> CIVector {
        return CIVector(x: x, y: image.extent.height - y)
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            assertionFailure()
            self = .up
        }
    }
}
