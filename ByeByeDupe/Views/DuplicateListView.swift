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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

}
