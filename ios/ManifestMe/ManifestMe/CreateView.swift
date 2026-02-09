//
//  CreateView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/6/26.
//

import SwiftUI
import AVKit
import PhotosUI
import Combine

struct ManifestationTemplate: Identifiable {
    let id = UUID()
    let name: String
    let keyword: String
    let icon: String
    let color: Color
}

struct CreateView: View {
    let templates = [
        ManifestationTemplate(name: "Beach Escape", keyword: "beach", icon: "sun.max.fill", color: .orange),
        ManifestationTemplate(name: "Wildlife Retreat", keyword: "wildlife", icon: "leaf.fill", color: .green),
        ManifestationTemplate(name: "Work Abroad", keyword: "work_abroad", icon: "airplane", color: .blue)
    ]
    
    @State private var selectedTemplate: ManifestationTemplate?
    @State private var userPrompt: String = ""
    @State private var isGenerating = false
    @State private var player: AVPlayer?
    @State private var errorMessage: String = ""
    
    // --- NEW: IDENTITY STATES ---
    @State private var hasProfileImage = false
    @State private var isCheckingProfile = true
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isUploading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("Choose Your Path")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                    
                    // CAROUSEL
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(templates) { template in
                                TemplateCard(template: template, isSelected: selectedTemplate?.id == template.id)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            selectedTemplate = template
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // INPUT
                    VStack(alignment: .leading) {
                        Text("Add details (optional)...")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.leading, 5)
                        
                        TextField("e.g. 'drinking a margarita'", text: $userPrompt)
                            .padding()
                            .background(Color(white: 0.1))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // --- THE GATEKEEPER BUTTON ---
                    if isCheckingProfile {
                        ProgressView().tint(.white)
                            .padding()
                    } else if !hasProfileImage {
                        // LOCKED: SHOW UPLOAD BUTTON
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                if isUploading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "camera.fill")
                                    Text("Upload Selfie to Unlock Magic")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.yellow) // Yellow means "Action Needed"
                            .cornerRadius(15)
                            .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .onChange(of: selectedPhotoItem) { oldValue, newItem in // <--- The Fix
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    uploadSelectedPhoto(data: data)
                                }
                            }
                        }
                    } else {
                        // UNLOCKED: SHOW MANIFEST BUTTON
                        Button(action: startManifestation) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text(selectedTemplate == nil ? "Select a Path" : "Manifest Vision")
                            }
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(selectedTemplate == nil ? Color.gray : Color.purple)
                            .cornerRadius(15)
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(selectedTemplate == nil || isGenerating)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    // VIDEO PLAYER
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
                                .onAppear { player.play() }
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
            .blur(radius: isGenerating ? 5 : 0)
            .onAppear {
                checkProfileStatus() // Check on load
            }
            
            if isGenerating {
                LoadingOverlay()
            }
        }
    }
    
    // --- NEW: API FUNCTIONS ---
    
    func checkProfileStatus() {
        guard let token = KeychainHelper.standard.read() else { return }
        guard let url = URL(string: "http://localhost:8000/api/profile/status/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exists = json["has_image"] as? Bool {
                DispatchQueue.main.async {
                    self.hasProfileImage = exists
                    self.isCheckingProfile = false
                }
            } else {
                // If error, assume false so they can try uploading
                DispatchQueue.main.async {
                    self.isCheckingProfile = false
                }
            }
        }.resume()
    }
    
    func uploadSelectedPhoto(data: Data) {
        guard let token = KeychainHelper.standard.read() else { return }
        isUploading = true
        errorMessage = ""
        
        guard let url = URL(string: "http://localhost:8000/api/profile/upload/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Multipart Form Data Dance
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isUploading = false
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Success! Unlock the gate.
                    withAnimation {
                        self.hasProfileImage = true
                    }
                } else {
                    errorMessage = "Upload failed. Please try again."
                }
            }
        }.resume()
    }
    
    // ... (Keep existing startManifestation logic) ...
    func startManifestation() {
         // ... (Paste your existing startManifestation logic here) ...
         // Or I can paste the full function if you need it.
         // Just ensure it matches the previous "CreateView.swift" logic.
        
        errorMessage = ""
        player = nil
        
        guard let token = KeychainHelper.standard.read() else {
            errorMessage = "Please log in again."
            return
        }
        
        guard let template = selectedTemplate else { return }
        
        isGenerating = true
        
        let finalPrompt = "\(template.keyword) - \(userPrompt)"
        
        guard let url = URL(string: "http://localhost:8000/api/manifest/") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = ["prompt": finalPrompt]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isGenerating = false
                
                if let error = error {
                    errorMessage = "Network Error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let videoUrlString = json["video_url"] as? String,
                   let videoUrl = URL(string: videoUrlString) {
                    
                    let newPlayer = AVPlayer(url: videoUrl)
                    newPlayer.play()
                    self.player = newPlayer
                    
                } else {
                    errorMessage = "Failed to process video."
                }
            }
        }.resume()
    }
}

// ... (Keep TemplateCard and LoadingOverlay structs) ...
struct TemplateCard: View {
    let template: ManifestationTemplate
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(template.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundStyle(template.color)
            }
            .padding(.bottom, 5)
            
            Text(template.name)
                .font(.headline)
                .foregroundStyle(.white)
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.purple)
                    .padding(.top, 2)
            }
        }
        .frame(width: 140, height: 160)
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

struct LoadingOverlay: View {
    @State private var isAnimating = false
    @State private var messageIndex = 0
    
    let messages = [
        "Aligning energy...",
        "Connecting to the cloud...",
        "Stitching your vision...",
        "Polishing pixels...",
        "Almost there..."
    ]
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.5), lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.5 : 1.0)
                    
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .shadow(color: .purple, radius: isAnimating ? 20 : 10)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
                
                VStack(spacing: 10) {
                    Text("Manifesting")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(messages[messageIndex])
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .transition(.opacity)
                        .id(messageIndex)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
    }
}

#Preview {
    CreateView()
}
