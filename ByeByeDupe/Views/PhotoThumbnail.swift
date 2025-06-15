//
//  PhotoThumbnail.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//

import SwiftUI
import Photos

struct PhotoThumbnail: View {
    var asset: PHAsset
    @State private var image: UIImage? = nil
    @State private var showViewer = false

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .onTapGesture {
                        showViewer = true
                    }
            } else {
                Color.gray
                    .frame(width: 100, height: 100)
            }
        }
        .onAppear(perform: loadThumbnail)
        .sheet(isPresented: $showViewer) {
            PhotoViewer(asset: asset)
        }
    }

    func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 150, height: 150),
            contentMode: .aspectFill,
            options: options
        ) { result, info in
            if let img = result {
                DispatchQueue.main.async {
                    self.image = img
                }
            } else {
                print("⚠️ Thumbnail request failed for asset \(asset.localIdentifier)")
                if let info = info {
                    print("Info: \(info)")
                }
            }
        }
    }
}
