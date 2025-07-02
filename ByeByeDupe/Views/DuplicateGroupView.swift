//
//  DuplicateGroupView.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//

import SwiftUI
import Photos

struct DuplicateGroupView: View {
    let group: [PHAsset]
    let onMerged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 📅 Date + Merge button in same HStack
            HStack {
                if let date = group.first?.creationDate {
                    Text(formattedDate(date))
                        .font(.headline)
                }

                Spacer()

                Button(action: {
                    mergeGroup()
                }) {
                    Text("Merge")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray4))
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)

            // 🖼️ Horizontal scroll of thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group, id: \.localIdentifier) { asset in
                        PhotoThumbnail(asset: asset)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 110)
        }
        .padding(.vertical, 12)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    func mergeGroup() {
        guard group.count > 1 else { return }

        // Step 1: Find best image (highest resolution)
        guard let bestAsset = group.max(by: {
            $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight
        }) else { return }

        // Step 2: Extract existing metadata
        SmartMergeHelper.getImageData(for: bestAsset) { imageData, bestMetadata in
            guard let bestMetadata = bestMetadata else {
                print("Could not read metadata from best image")
                return
            }

            let hasLocation = bestAsset.location != nil
            let hasDate = bestAsset.creationDate != nil

            var needsRecreate = false
            var mergedDate: Date? = bestAsset.creationDate
            var mergedLocation: CLLocation? = bestAsset.location

            for other in group where other.localIdentifier != bestAsset.localIdentifier {
                if !hasDate, let otherDate = other.creationDate {
                    mergedDate = otherDate
                    needsRecreate = true
                }

                if !hasLocation, let otherLoc = other.location {
                    mergedLocation = otherLoc
                    needsRecreate = true
                }
            }

            if needsRecreate {
                // Step 3a: Recreate the image with merged metadata
                SmartMergeHelper.mergeAndSave(bestAsset: bestAsset, from: group) { success in
                    print(success ? "Recreated with full metadata" : "Merge failed")
                    if success {
                        DispatchQueue.main.async {
                            onMerged()
                        }
                    }
                }
            } else {
                // Step 3b: Update in-place
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetChangeRequest(for: bestAsset)
                    request.creationDate = mergedDate
                    request.location = mergedLocation

                    let assetsToDelete = group.filter { $0 != bestAsset }
                    PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)

                } completionHandler: { success, error in
                    if success {
                        print("In-place update with no recreation")
                        DispatchQueue.main.async {
                                                onMerged()
                                            }
                    } else {
                        print("Error: \(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
    }

}
