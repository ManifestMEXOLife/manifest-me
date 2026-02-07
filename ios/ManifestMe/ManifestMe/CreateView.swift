//
//  CreateView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/6/26.
//

import SwiftUI
import AVKit

struct CreateView: View {
    @State private var prompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var player: AVPlayer?
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            //Background color
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                Text("Manifest Your Vision")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Input area
                VStack(alignment: .leading) {
                    Text("I want to see...")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.leading, 5)
                    
                    TextEditor(text: $prompt)
                        .scrollContentBackground(.hidden)
                        .background(Color(white: 0.1))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                //The magic button
                Button(action: startManifestation) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Manifest Video")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(prompt.isEmpty ? Color.gray : Color.purple)
                    .cornerRadius(15)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .disabled(prompt.isEmpty || isGenerating)
                .padding(.horizontal)
                
                // RESULT AREA (Video or Error)
                if let player = player {
                    VStack {
                        Text("✨ Your Manifestation ✨")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        
                        VideoPlayer(player: player)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple, lineWidth: 1)
                            )
                            .onAppear {
                                // Double check it's playing when it appears on screen
                                player.play()
                            }
                    }
                    .padding()
                    .transition(.scale)
                    
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
        }
    }
    
    func startManifestation() {
        // Clear previous
        errorMessage = ""
        player = nil
        
        guard let token = KeychainHelper.standard.read() else {
            errorMessage = "Please log in again."
            return
        }
        
        isGenerating = true
        
        guard let url = URL(string: "http://localhost:8000/api/manifest/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["prompt": prompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isGenerating = false
                
                if let error = error {
                    errorMessage = "Network Error: \(error.localizedDescription)"
                    return
                }
                
                // CHANGE 3: The Auto-Play Logic
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let videoUrlString = json["video_url"] as? String,
                       let videoUrl = URL(string: videoUrlString) {
                        
                        // Create the player
                        let newPlayer = AVPlayer(url: videoUrl)
                        
                        // Play immediately!
                        newPlayer.play()
                        
                        // Save it to state
                        self.player = newPlayer
                        
                    } else {
                        errorMessage = "Failed to process video."
                    }
                }
            }
        }.resume()
    }
}

#Preview {
    CreateView()
}
