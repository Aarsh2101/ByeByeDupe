//
//  DuplicateListView.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/10/25.
//

import SwiftUI
import Photos

struct DuplicateListView: View {
    @State var duplicateGroups: [[PHAsset]]
    @State private var isMergingAll = false


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                mergeAllGroups()
            }) {
                Text("Merge All")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMergingAll ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .disabled(isMergingAll || duplicateGroups.isEmpty)

            // 📸 Scrollable list of duplicates
            ScrollView {
                ForEach(duplicateGroups.indices, id: \.self) { index in
                    DuplicateGroupView(
                        group: duplicateGroups[index],
                        onMerged: {
                            duplicateGroups.remove(at: index)
                        }
                    )
                }
            }
        }
        .navigationTitle("Duplicates")
    }
    
    func mergeAllGroups() {
        isMergingAll = true
        var groupsCopy = duplicateGroups

        func mergeNext() {
            guard !groupsCopy.isEmpty else {
                isMergingAll = false
                return
            }

            let group = groupsCopy.removeFirst()

            // Step 1: Get the best asset
            guard let bestAsset = group.max(by: {
                $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight
            }) else {
                mergeNext()
                return
            }

            // Step 2: Check if we need to recreate or can update in-place
            SmartMergeHelper.getImageData(for: bestAsset) { _, bestMetadata in
                var needsRecreate = false
                var mergedDate: Date? = bestAsset.creationDate
                var mergedLocation: CLLocation? = bestAsset.location

                for other in group where other.localIdentifier != bestAsset.localIdentifier {
                    if bestAsset.creationDate == nil, let otherDate = other.creationDate {
                        mergedDate = otherDate
                        needsRecreate = true
                    }
                    if bestAsset.location == nil, let otherLoc = other.location {
                        mergedLocation = otherLoc
                        needsRecreate = true
                    }
                }

                let onFinish: () -> Void = {
                    DispatchQueue.main.async {
                        duplicateGroups.removeAll { $0 == group }
                        mergeNext()
                    }
                }

                if needsRecreate {
                    SmartMergeHelper.mergeAndSave(bestAsset: bestAsset, from: group) { success in
                        print(success ? "✅ Group recreated" : "❌ Merge failed")
                        onFinish()
                    }
                } else {
                    PHPhotoLibrary.shared().performChanges {
                        let request = PHAssetChangeRequest(for: bestAsset)
                        request.creationDate = mergedDate
                        request.location = mergedLocation
                        PHAssetChangeRequest.deleteAssets(group.filter { $0 != bestAsset } as NSArray)
                    } completionHandler: { success, error in
                        print(success ? "✅ In-place group merged" : "❌ Error: \(error?.localizedDescription ?? "")")
                        onFinish()
                    }
                }
            }
        }

        mergeNext()
    }

}
