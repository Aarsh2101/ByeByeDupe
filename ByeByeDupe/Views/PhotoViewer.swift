//
//  PhotoViewer.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/10/25.
//

import SwiftUI
import Photos

struct PhotoViewer: View {
    let asset: PHAsset
    @Environment(\.dismiss) var dismiss
    @State private var fullImage: UIImage?

    var body: some View {
        ZStack {
            if let img = fullImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                ProgressView("Loading...")
            }

            VStack {
                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                Spacer()
            }
            .padding()
        }
        .onAppear(perform: loadFullImage)
    }

    func loadFullImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let img = image {
                self.fullImage = img
            }
        }
    }
}
