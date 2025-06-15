//
//  PhotoLibraryViewModel.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//

import Photos
import SwiftUI

class PhotoLibraryViewModel: ObservableObject {
    @Published var showingDuplicates = false
    @Published var assets: [PHAsset] = []
    @Published var duplicates: [[PHAsset]] = []

    init() {
        requestPermission()
    }

    func requestPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                self.loadPhotos()
            } else {
                print("Permission not granted.")
            }
        }
    }

    func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var loadedAssets: [PHAsset] = []

        result.enumerateObjects { asset, _, _ in
            loadedAssets.append(asset)
        }

        DispatchQueue.main.async {
            self.assets = loadedAssets
        }
    }

    func detectDuplicates(completion: @escaping () -> Void) {
        let detector = DuplicateDetector()
        print("Detecting duplicates...")
        detector.findDuplicates(from: self.assets) { groups in
            self.duplicates = groups
            completion()
        }
    }
}
