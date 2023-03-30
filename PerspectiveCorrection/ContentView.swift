//
//  ContentView.swift
//  PerspectiveCorrection
//
//  Created by 清浦 駿 on 2023/03/22.
//

import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    private enum CorrectMode {
        case auto
        case manual
    }

    @State private var correctMode: CorrectMode = .auto
    @State private var image: UIImage?
    @State private var photosPickerItems: [PhotosPickerItem] = .init()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                PhotosPicker(
                    selection: $photosPickerItems,
                    maxSelectionCount: 1,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                }
                .padding(.horizontal)
                .onChange(of: photosPickerItems) { newPhotoPickerItems in
                    Task {
                        let data = try await newPhotoPickerItems.first?.loadTransferable(type: Data.self)
                        guard let data else { return }
                        self.image = UIImage(data: data)
                    }
                }
            }

            Picker("correctMode", selection: $correctMode) {
                Text("auto").tag(CorrectMode.auto)
                Text("manual").tag(CorrectMode.manual)
            }
            .pickerStyle(.segmented)
            .padding()

            switch correctMode {
            case .auto:
                AutoCorrectView(image: $image)
            case .manual:
                ManualCorrectView(image: $image)
            }

            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
