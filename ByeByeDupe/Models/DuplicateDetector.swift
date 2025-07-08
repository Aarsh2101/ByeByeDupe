//
//  DuplicateDetector.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//
import Photos
import UIKit


class DuplicateDetector {
    struct PhotoHash: Hashable {
        let hash: String
    }
    
    func resize(image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func getFileSize(for asset: PHAsset) -> Int {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return 0 }
        
        if let fileSize = resource.value(forKey: "fileSize") as? Int {
            return fileSize
        }
        
        return 0
    }
    
    func hammingDistance(_ a: String, _ b: String) -> Int {
        zip(a, b).filter { $0 != $1 }.count
    }
    
    func generateHash(for image: UIImage) -> String {
        guard let resized = resize(image: image, to: CGSize(width: 8, height: 8)),
              let cgImage = resized.cgImage else {
            return ""
        }
        
        var total: CGFloat = 0
        var pixels: [CGFloat] = []
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        let grayscale = ciImage.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0])
        
        guard let bitmap = context.createCGImage(grayscale, from: grayscale.extent) else { return "" }
        
        let width = bitmap.width
        let height = bitmap.height
        let data = CFDataGetBytePtr(bitmap.dataProvider!.data)!
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let gray = CGFloat(data[offset])
                total += gray
                pixels.append(gray)
            }
        }
        
        let avg = total / CGFloat(pixels.count)
        let hash = pixels.map { $0 > avg ? "1" : "0" }.joined()
        
        return hash
    }
    
    
    func findDuplicates(from assets: [PHAsset], threshold: Int = 5, completion: @escaping ([[PHAsset]]) -> Void) {
        var hashMap: [PhotoHash: [PHAsset]] = [:]
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat   // more reliable
        options.isSynchronous = true
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true       // allows iCloud download
        
        DispatchQueue.global(qos: .userInitiated).async {
            for asset in assets {
                // ⚠️ Skip assets that don’t contain a photo resource
                let resources = PHAssetResource.assetResources(for: asset)
                guard resources.contains(where: { $0.type == .photo }) else {
                    print("⚠️ Skipping asset with no valid photo resource: \(asset.localIdentifier)")
                    continue
                }
                
                let targetSize = CGSize(width: 100, height: 100)
                var imageResult: UIImage?
                
                let semaphore = DispatchSemaphore(value: 0)
                manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { result, info in
                    imageResult = result
                    if result == nil {
                        print("❌ Failed to load image for asset \(asset.localIdentifier). Info: \(String(describing: info))")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                
                guard let image = imageResult else { continue }
                let hashString = self.generateHash(for: image)
                var found = false
                
                for (key, _ ) in hashMap {
                    if self.hammingDistance(hashString, key.hash) <= threshold {
                        hashMap[key]?.append(asset)
                        found = true
                        break
                    }
                }
                
                if !found {
                    hashMap[PhotoHash(hash: hashString)] = [asset]
                }
                
            }
            
            let duplicates = hashMap.values.filter { $0.count > 1 }
            
            DispatchQueue.main.async {
                completion(duplicates)
            }
        }
    }
    
}
