//
//  VideoService.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import Foundation
import Combine

// 1. The Data Model for the Tile View
struct ManifestationVideo: Identifiable, Decodable {
    // We keep this as a 'let' with a default value
    let id = UUID()
    let url: String
    let name: String
    
    // 🔑 ADD THIS ENUM
    // This acts like a filter. It tells Swift strictly which keys to map from the JSON.
    // Since 'id' is NOT in this list, Swift ignores it during decoding
    // and just uses the default UUID() we created above.
    private enum CodingKeys: String, CodingKey {
        case url
        case name
    }
}

class VideoService: ObservableObject {
    // --- STATE ---
    @Published var isManifesting: Bool = false
    @Published var currentVideoURL: URL? = nil
    @Published var errorMessage: String = ""
    
    // --- NEW: THE SHOEBOX (Your list of past videos) ---
    @Published var myVideos: [ManifestationVideo] = []
    
    // Fake progress for the UI (0.0 to 1.0)
    @Published var progress: Float = 0.0
    private var progressTimer: Timer?
    
    // ⚠️ CHECK THIS: Ensure this matches your environment (Simulator vs Device)
    private let baseURL = "http://127.0.0.1:8000/api"

    // --- FUNCTION 1: FETCH PAST VIDEOS (The Tile View) ---
    func fetchVideos(token: String) {
        guard let url = URL(string: "\(baseURL)/videos/") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("📥 Fetching videos...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                guard let data = data else { return }
                
                // 1. 🔍 DEBUG: Print the raw JSON String
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("🔍 Backend Response: \(rawJSON)")
                }
                
                // 2. Check for Success Code (200)
                if httpResponse.statusCode == 200 {
                    do {
                        let videos = try JSONDecoder().decode([ManifestationVideo].self, from: data)
                        self.myVideos = videos
                        print("✅ Loaded \(videos.count) videos.")
                    } catch {
                        print("❌ Decode Error: \(error)")
                    }
                } else {
                    // 3. Handle Error (401, 403, 500)
                    print("⚠️ Server returned error code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    // --- FUNCTION 2: CREATE NEW VIDEO (The Manifestation) ---
    func manifest(prompt: String, token: String) {
        // 1. Lock the UI
        self.isManifesting = true
        self.errorMessage = ""
        self.progress = 0.0
        self.currentVideoURL = nil
        
        // 2. Start "Fake" Progress Bar
        startProgressSimulation()
        
        // 3. Prepare Request
        guard let url = URL(string: "\(baseURL)/manifest/") else { return }
        
        let body: [String: Any] = ["prompt": prompt]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // 4. Send to Backend
        print("🚀 Sending Dream: \(prompt)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.stopProgress() // Stop the fake timer
                
                if let error = error {
                    self.isManifesting = false
                    self.errorMessage = "Failed: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                
                if httpResponse.statusCode == 200 {
                    // SUCCESS!
                    self.handleSuccess(data: data)
                    
                    // REFRESH THE GRID! (So the new video appears)
                    self.fetchVideos(token: token)
                    
                } else {
                    self.isManifesting = false
                    self.errorMessage = "Server Error: \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
    
    private func handleSuccess(data: Data?) {
        guard let data = data else { return }
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = json["video_url"] as? String,
               let url = URL(string: urlString) {
                
                self.currentVideoURL = url
                self.isManifesting = false // Unlock the UI
                print("✨ Video Ready: \(url)")
            }
        } catch {
            self.errorMessage = "Could not read video link."
            self.isManifesting = false
        }
    }
    
    // --- HELPER: FAKE PROGRESS BAR ---
    private func startProgressSimulation() {
        self.progress = 0.0
        self.progressTimer?.invalidate()
        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.progress < 0.90 {
                self.progress += 0.01
            }
        }
    }
    
    private func stopProgress() {
        self.progressTimer?.invalidate()
        self.progress = 1.0
    }
}
