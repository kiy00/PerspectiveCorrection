//
//  AutoCorrectView.swift
//  PerspectiveCorrection
//
//  Created by 清浦 駿 on 2023/03/29.
//

import SwiftUI
import Vision

struct AutoCorrectView: View {
    @Binding var image: UIImage?

    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()

                Button("AutoCorrect") {
                    guard let cgImage = image.cgImage else { return }

                    recognizeRectangle(in: cgImage) { results in
                        guard let result = results.first else { return }

                        let ciImage = CIImage(cgImage: cgImage)

                        // Visionの座標系はUIkitなどとは上下が逆になっている。そのため、(1 - y)をしてUIKitの座標系に合わせる必要がある。
                        let topLeft = CGPoint(x: result.topLeft.x, y: 1 - result.topLeft.y)
                        let topRight = CGPoint(x: result.topRight.x, y: 1 - result.topRight.y)
                        let bottomLeft = CGPoint(x: result.bottomLeft.x, y: 1 - result.bottomLeft.y)
                        let bottomRight = CGPoint(x: result.bottomRight.x, y: 1 - result.bottomRight.y)

                        // Visionで読み取った座標は正規化されていて、0~1で返ってくるため、VNImagePointForNormalizedPointを使用して画像の大きさに合わせる必要がある
                        let deNormalizedTopLeft = VNImagePointForNormalizedPoint(topLeft, Int(ciImage.extent.width), Int(ciImage.extent.height))
                        let deNormalizedTopRight = VNImagePointForNormalizedPoint(topRight, Int(ciImage.extent.width), Int(ciImage.extent.height))
                        let deNormalizedBottomLeft = VNImagePointForNormalizedPoint(bottomLeft, Int(ciImage.extent.width), Int(ciImage.extent.height))
                        let deNormalizedBottomRight = VNImagePointForNormalizedPoint(bottomRight, Int(ciImage.extent.width), Int(ciImage.extent.height))

                        Task {
                            let correctedImage = await ImageCorrector.getPerspectiveCorrectedImage(
                                image: CIImage(cgImage: cgImage).oriented(CGImagePropertyOrientation(image.imageOrientation)),
                                topLeft: deNormalizedTopLeft,
                                topRight: deNormalizedTopRight,
                                bottomLeft: deNormalizedBottomLeft,
                                bottomRight: deNormalizedBottomRight
                            )

                            guard let cgImage = CIContext().createCGImage(correctedImage, from: correctedImage.extent) else { return }
                            self.image = UIImage(cgImage: cgImage)
                        }
                    }
                }
            }
        }
    }

    private func recognizeRectangle(in cgImage: CGImage, handler: @escaping([VNRectangleObservation]) -> Void) {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        let request = VNDetectRectanglesRequest { (request, error) in
            guard let observations = request.results as? [VNRectangleObservation] else { return }

            handler(observations)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
}

struct AutoCorrectView_Previews: PreviewProvider {
    static var previews: some View {
        AutoCorrectView(image: .constant(nil))
    }
}
