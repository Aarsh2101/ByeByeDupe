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
        print("Merging group of \(group.count) assets")
        // Add actual delete/merge logic here
    }
}
