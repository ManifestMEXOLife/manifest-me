//
//  ManifestPathView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI

struct ManifestPathView: View {
    @State private var selectedPath: String? = nil
    @State private var showSheet = false
    @EnvironmentObject var videoService: VideoService // To show progress bar
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading) {
                    Text("Choose Your Path")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                    
                    // IF MANIFESTING: Show Progress Bar
                    if videoService.isManifesting {
                        // (Paste your Manifesting Status Card code here from previous steps)
                        // ...
                        Text("Manifesting in progress...")
                            .foregroundColor(.yellow)
                            .padding()
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // TILE 1: BEACH
                            PathCard(title: "Beach Escape", icon: "sun.max.fill", color: .orange) {
                                selectedPath = "beach"
                                showSheet = true
                            }
                            
                            // TILE 2: WORK ABROAD
                            PathCard(title: "Global Career", icon: "briefcase.fill", color: .blue) {
                                selectedPath = "work"
                                showSheet = true
                            }
                            
                            // TILE 3: WILDLIFE
                            PathCard(title: "Nature Retreat", icon: "leaf.fill", color: .green) {
                                selectedPath = "wildlife"
                                showSheet = true
                            }
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                // Pass the 'hidden' keyword to the CreateView
                CreateView(contextKeyword: selectedPath ?? "")
            }
        }
    }
}

// Helper View for the Tiles
struct PathCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(color)
                    .padding()
                    .background(Circle().fill(Color.white.opacity(0.1)))
                
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
    }
}
