//
//  PhotoLibraryViewModel.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//

import Photos
import SwiftUI

class PhotoLibraryViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var assets: [PHAsset] = []
    @Published var duplicates: [[PHAsset]] = []
    @Published var isScanning: Bool = false

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        requestPermission()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
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
        isScanning = true
        let detector = DuplicateDetector()
        detector.findDuplicates(from: self.assets) { groups in
        DispatchQueue.main.async {
                self.duplicates = groups
                self.isScanning = false
                completion()
            }
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.loadPhotos()
        }
    }
}
