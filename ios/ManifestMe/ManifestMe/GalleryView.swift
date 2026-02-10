//
//  GalleryView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var videoService: VideoService
    
    let columns = [GridItem(.flexible())] // 1 Column Feed Style
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(videoService.myVideos) { video in
                            NavigationLink(destination: FullScreenPlayer(videoURL: URL(string: video.url)!)) {
                                
                                // Use ZStack to layer the button ON TOP of the image
                                ZStack {
                                    // 1. The Thumbnail Image
                                    VideoThumbnail(url: URL(string: video.url)!)
                                        .aspectRatio(16/9, contentMode: .fill)
                                        .cornerRadius(12)
                                        .clipped()
                                    
                                    // 2. The Play Button Overlay
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 50)) // Nice and big
                                        .foregroundColor(.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2) // Shadow for visibility
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("My Manifestations")
            }
            .onAppear {
                if let token = KeychainHelper.standard.read() {
                    videoService.fetchVideos(token: token)
                }
            }
        }
    }
}
