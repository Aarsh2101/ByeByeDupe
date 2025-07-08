//
//  SmartMergeHelper.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/14/25.
//

import Photos
import ImageIO
import MobileCoreServices
import UIKit

class SmartMergeHelper {
    
    /// Merge metadata from all assets in `group` with the image data of `bestAsset` and write the result to a temporary file. The caller is responsible for deleting the returned file when finished.
    static func mergedImageURL(bestAsset: PHAsset, from group: [PHAsset], completion: @escaping (URL?) -> Void) {
        getImageData(for: bestAsset) { bestImageData, bestMetadata in
            guard let bestImageData = bestImageData, let bestMetadata = bestMetadata else {
                completion(nil)
                return
            }
            
            var mergedMetadata = bestMetadata
            let groupWithoutBest = group.filter { $0.localIdentifier != bestAsset.localIdentifier }
            
            let dispatchGroup = DispatchGroup()
            for asset in groupWithoutBest {
                dispatchGroup.enter()
                getImageData(for: asset) { _, metadata in
                    if let metadata = metadata {
                        mergedMetadata = merge(metadata1: mergedMetadata, metadata2: metadata)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                let outputURL = writeImageWithMetadata(imageData: bestImageData, metadata: mergedMetadata)
                completion(outputURL)
            }
        }
    }
    
    static func mergeAndSave(bestAsset: PHAsset, from group: [PHAsset], completion: @escaping (Bool) -> Void) {
        // Step 1: Extract image data from best asset
        getImageData(for: bestAsset) { bestImageData, bestMetadata in
            guard let bestImageData = bestImageData, let bestMetadata = bestMetadata else {
                completion(false)
                return
            }
            
            // Step 2: Collect metadata from others
            var mergedMetadata = bestMetadata
            
            let groupWithoutBest = group.filter { $0.localIdentifier != bestAsset.localIdentifier }
            
            let dispatchGroup = DispatchGroup()
            
            for asset in groupWithoutBest {
                dispatchGroup.enter()
                getImageData(for: asset) { _, metadata in
                    if let metadata = metadata {
                        mergedMetadata = merge(metadata1: mergedMetadata, metadata2: metadata)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Step 3: Write new image with merged metadata
                guard let outputURL = writeImageWithMetadata(imageData: bestImageData, metadata: mergedMetadata) else {
                    completion(false)
                    return
                }
                
                // Step 4: Save to photo library and delete originals
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: outputURL)
                    PHAssetChangeRequest.deleteAssets(group as NSArray)
                } completionHandler: { success, error in
                    try? FileManager.default.removeItem(at: outputURL)
                    if success {
                        print("Merged successfully.")
                    } else {
                        print("Error saving: \(error?.localizedDescription ?? "Unknown")")
                    }
                    completion(success)
                }
            }
        }
    }
    
    public static func getImageData(for asset: PHAsset, completion: @escaping (Data?, [String: Any]?) -> Void) {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else {
            completion(nil, nil)
            return
        }
        
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let data = NSMutableData()
        PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { chunk in
            data.append(chunk)
        }) { error in
            if let error = error {
                print("Failed to get data for \(asset.localIdentifier): \(error)")
                completion(nil, nil)
            } else {
                let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
                let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as? [String: Any]
                completion(data as Data, metadata)
            }
        }
    }
    
    private static func merge(metadata1: [String: Any], metadata2: [String: Any]) -> [String: Any] {
        var merged = metadata1
        
        for (key, value) in metadata2 {
            if let valueDict = value as? [String: Any],
               let existingDict = merged[key] as? [String: Any] {
                merged[key] = merge(metadata1: existingDict, metadata2: valueDict)
            } else if merged[key] == nil || "\(merged[key]!)" == "" {
                merged[key] = value
            }
        }
        
        return merged
    }
    
    private static func writeImageWithMetadata(imageData: Data, metadata: [String: Any]) -> URL? {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged-\(UUID().uuidString).jpg")
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(imageSource),
              let destination = CGImageDestinationCreateWithURL(tmpURL as CFURL, type, 1, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return tmpURL
    }
}
