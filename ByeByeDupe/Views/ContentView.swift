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
    @State private var showThresholdPicker = false
    @State private var tempThreshold = 5

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

                if viewModel.isScanning {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ProgressView("Scanning...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                }

                VStack(spacing: 8) {
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
                    }
                    .disabled(viewModel.isScanning)
                    .padding([.horizontal, .bottom], 16)
                }
            }
            .navigationTitle("Your Photos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        tempThreshold = viewModel.detectionThreshold
                        showThresholdPicker = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .navigationDestination(isPresented: $showDuplicates) {
                DuplicateListView(duplicateGroups: viewModel.duplicates)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showThresholdPicker) {
                VStack {
                    Text("Select Threshold")
                        .font(.headline)
                        .padding()

                    Picker("Threshold", selection: $tempThreshold) {
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 150)

                    Divider()

                    HStack {
                        Button("Cancel") {
                            showThresholdPicker = false
                        }
                        .padding()

                        Spacer()

                        Button("Done") {
                            viewModel.detectionThreshold = tempThreshold * 3
                            showThresholdPicker = false
                        }
                        .bold()
                        .padding()
                    }
                }
                .presentationDetents([.height(300)])
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoLibraryViewModel())
}
