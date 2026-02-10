//
//  VideoThumbnail.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI
import AVKit

struct VideoThumbnail: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder while loading
                Color(white: 0.1)
                ProgressView()
                    .tint(.white)
            }
        }
        // This triggers the background generator when the tile appears
        .task {
            if image == nil {
                image = await generateThumbnail(for: url)
            }
        }
    }
    
    // The Engine: Grabs the frame at 1.0 second mark
    private func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            // Grab a frame at the 1-second mark (often better than 0.0 which can be black)
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail failed: \(error)")
            return nil
        }
    }
}
