//
//  ProfileView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var profileImageURL: URL?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // AVATAR
                AsyncImage(url: profileImageURL) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.yellow, lineWidth: 2))
                
                // USER INFO
                Text("Dreamer")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                // LOGOUT BUTTON
                Button(action: {
                    authService.logout()
                }) {
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 50)
        }
        .onAppear {
            fetchProfile()
        }
    }
    
    func fetchProfile() {
        guard let token = KeychainHelper.standard.read() else { return }
        
        // ⚠️ Make sure this URL matches your backend (localhost or IP)
        guard let url = URL(string: "http://127.0.0.1:8000/api/profile/status/") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("👤 Checking profile image...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // 1. Check for basic errors
                if let error = error {
                    print("❌ Profile Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                // 2. Parse the JSON
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        
                        // 3. Did the backend say "has_image": true?
                        if let hasImage = json["has_image"] as? Bool, hasImage == true,
                           let urlString = json["image_url"] as? String {
                            
                            // 4. Update the UI!
                            self.profileImageURL = URL(string: urlString)
                            print("✅ Loaded Profile Pic!")
                            
                        } else {
                            print("🤷‍♂️ No custom image found. Keeping placeholder.")
                        }
                    }
                } catch {
                    print("❌ JSON Decode Error: \(error)")
                }
            }
        }.resume()
    }
}
