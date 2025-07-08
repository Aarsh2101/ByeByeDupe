# ByeByeDupe

ByeByeDupe is an iOS application that scans the photo library for duplicate images and helps you merge or remove them. It groups potential duplicates based on a perceptual hash and provides tools to merge metadata or delete unwanted copies.

## Features

- **Duplicate detection** using a perceptual hash algorithm with an adjustable threshold.
- **Smart merge** of duplicate groups retaining the highest quality image while combining metadata such as creation date and location.
- View thumbnails in a grid and tap to see a full screen preview.
- Merge duplicates individually or all at once.

## Building and Running

1. Install the latest Xcode (tested with iOS deployment target 18.5, Swift 5).
2. Open `ByeByeDupe.xcodeproj` in Xcode.
3. Select a simulator or connected device.
4. Build and run the `ByeByeDupe` scheme.
5. Grant Photos permission when prompted.

## Usage

1. After launching, your photos are shown in a grid.
2. Tap **Find Duplicates** to scan using the selected threshold. Adjust the threshold from the toolbar slider if necessary.
3. Review groups of detected duplicates. Each group lists the creation date and thumbnails.
4. Tap **Merge** on a group to keep the best image and merge metadata. Use **Merge All** to process every group.

## License

This project is licensed under the MIT License.
