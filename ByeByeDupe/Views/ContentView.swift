//
//  ContentView.swift
//  ByeByeDupe
//
//  Created by Aarsh Patel on 6/9/25.
//
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = PhotoLibraryViewModel()
    let columns = [GridItem(.adaptive(minimum: 100))]
    @State private var showDuplicates = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                            PhotoThumbnail(asset: asset)
                        }
                    }
                    .padding(.bottom, 80)
                    .padding(.horizontal)
                }

                Button(action: {
                    viewModel.detectDuplicates {
                        showDuplicates = true
                    }
                }) {
                    Text("Find Duplicates")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding([.horizontal, .bottom], 16)
                }
            }
            .navigationTitle("Your Photos")
            .navigationDestination(isPresented: $showDuplicates) {
                DuplicateListView(duplicateGroups: viewModel.duplicates)
                    .environmentObject(viewModel) // pass down to children
            }
        }
        .environmentObject(viewModel) // make viewModel available app-wide
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoLibraryViewModel())
}
