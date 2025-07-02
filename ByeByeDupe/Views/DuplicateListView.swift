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
    
    struct MergeOperation {
        let group: [PHAsset]
        let bestAsset: PHAsset
        let mergedDate: Date?
        let mergedLocation: CLLocation?
        let outputURL: URL?
    }

    func mergeAllGroups() {
        isMergingAll = true
        let groups = duplicateGroups
        var operations: [MergeOperation] = []

        func prepareNext(_ remaining: [[PHAsset]]) {
            guard let group = remaining.first else {
                performBatch(with: operations)
                return
            }

            let rest = Array(remaining.dropFirst())

            guard let bestAsset = group.max(by: { $0.pixelWidth * $0.pixelHeight < $1.pixelWidth * $1.pixelHeight }) else {
                prepareNext(rest)
                return
            }

            SmartMergeHelper.getImageData(for: bestAsset) { _, _ in
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

                if needsRecreate {
                    SmartMergeHelper.mergedImageURL(bestAsset: bestAsset, from: group) { url in
                        operations.append(MergeOperation(group: group, bestAsset: bestAsset, mergedDate: mergedDate, mergedLocation: mergedLocation, outputURL: url))
                        prepareNext(rest)
                    }
                } else {
                    operations.append(MergeOperation(group: group, bestAsset: bestAsset, mergedDate: mergedDate, mergedLocation: mergedLocation, outputURL: nil))
                    prepareNext(rest)
                }
            }
        }

        func performBatch(with ops: [MergeOperation]) {
            PHPhotoLibrary.shared().performChanges {
                for op in ops {
                    if let url = op.outputURL {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                        PHAssetChangeRequest.deleteAssets(op.group as NSArray)
                    } else {
                        let request = PHAssetChangeRequest(for: op.bestAsset)
                        request.creationDate = op.mergedDate
                        request.location = op.mergedLocation
                        let toDelete = op.group.filter { $0 != op.bestAsset }
                        PHAssetChangeRequest.deleteAssets(toDelete as NSArray)
                    }
                }
            } completionHandler: { success, error in
                for op in ops {
                    if let url = op.outputURL {
                        try? FileManager.default.removeItem(at: url)
                    }
                }

                DispatchQueue.main.async {
                    duplicateGroups.removeAll()
                    isMergingAll = false
                    print(success ? "✅ All groups merged" : "❌ Error: \(error?.localizedDescription ?? "")")
                }
            }
        }

        prepareNext(groups)
    }

}
