//
//  ManualCorrectView.swift
//  PerspectiveCorrection
//
//  Created by 清浦 駿 on 2023/03/22.
//

import SwiftUI

class AdjustableRectangleModel: ObservableObject {
    @Published var topLeft: CGPoint = Const.topLeft
    @Published var topRight: CGPoint = Const.topRight
    @Published var bottomLeft: CGPoint = Const.bottomLeft
    @Published var bottomRight: CGPoint = Const.bottomRight

    func reset() {
        topLeft = Const.topLeft
        topRight = Const.topRight
        bottomLeft = Const.bottomLeft
        bottomRight = Const.bottomRight
    }

    private struct Const {
        static let topLeft: CGPoint = .zero
        static let topRight: CGPoint = .init(x: 100, y: 0)
        static let bottomLeft: CGPoint = .init(x: 0, y: 100)
        static let bottomRight: CGPoint = .init(x: 100, y: 100)
    }
}

struct AdjustableRectangle: View {
    @ObservedObject var model: AdjustableRectangleModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.addLines([
                    model.topLeft,
                    model.topRight,
                    model.bottomRight,
                    model.bottomLeft
                ])
                path.closeSubpath()
            }
            .stroke(style: .init(lineWidth: 1.5, dash: [5, 3]))
            .fill(Color.white)

            CornerCircle(position: $model.topLeft)
            CornerCircle(position: $model.topRight)
            CornerCircle(position: $model.bottomRight)
            CornerCircle(position: $model.bottomLeft)
        }
    }

    private struct CornerCircle: View {
        @Binding var position: CGPoint

        var body: some View {
            Circle()
                .fill(Color.blue)
                .frame(width: 10)
                .position(position)
                .gesture(DragGesture().onChanged({ self.position = $0.location }))
        }
    }
}

struct ManualCorrectView: View {
    @StateObject private var adjustableRectangleModel: AdjustableRectangleModel = .init()

    @State private var imageViewSize: CGSize = .zero

    @Binding var image: UIImage?

    var body: some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        AdjustableRectangle(model: adjustableRectangleModel)

                        GeometryReader { proxy -> Color in
                            DispatchQueue.main.async {
                                imageViewSize = proxy.size
                            }
                            return .clear
                        }
                    }

                Button("ManualCorrect") {
                    guard let cgImage = image.cgImage else { return }

                    let widthRatio = image.size.width / imageViewSize.width
                    let heightRatio = image.size.height / imageViewSize.height

                    Task {
                        let correctedImage = await ImageCorrector.getPerspectiveCorrectedImage(
                            image: CIImage(cgImage: cgImage).oriented(CGImagePropertyOrientation(image.imageOrientation)),
                            topLeft: adjustableRectangleModel.topLeft.multipliedBy(widthRatio: widthRatio, heightRatio: heightRatio),
                            topRight: adjustableRectangleModel.topRight.multipliedBy(widthRatio: widthRatio, heightRatio: heightRatio),
                            bottomLeft: adjustableRectangleModel.bottomLeft.multipliedBy(widthRatio: widthRatio, heightRatio: heightRatio),
                            bottomRight: adjustableRectangleModel.bottomRight.multipliedBy(widthRatio: widthRatio, heightRatio: heightRatio)
                        )

                        guard let cgImage = CIContext().createCGImage(correctedImage, from: correctedImage.extent) else { return }
                        self.image = UIImage(cgImage: cgImage)

                        adjustableRectangleModel.reset()
                    }
                }
            }
        }
    }
}

struct ManualCorrectView_Previews: PreviewProvider {
    static var previews: some View {
        ManualCorrectView(image: .constant(nil))
    }
}

private extension CGPoint {
    func multipliedBy(widthRatio: CGFloat, heightRatio: CGFloat) -> Self {
        return .init(x: x * widthRatio, y: y * heightRatio)
    }
}
