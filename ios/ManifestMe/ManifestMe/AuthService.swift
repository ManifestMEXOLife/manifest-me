//
//  AuthService.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import Foundation
import Combine

class AuthService: ObservableObject {
    // --- STATE VARIABLES ---
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // --- CONFIGURATION ---
    // ⚠️ IMPORTANT: Change this based on where you are running the app
    // Simulator: "http://127.0.0.1:8000/api"
    // Physical Device: "http://YOUR_MAC_LOCAL_IP:8000/api" (e.g. 192.168.1.5)
    // --- CONFIGURATION ---
//    #if DEBUG
//    // For local testing on your Mac
//    private let baseURL = "http://127.0.0.1:8000/api"
//    #else
    // Your live Cloud Run URL
    private let baseURL = "https://manifest-me-api-79704250837.us-central1.run.app/api"
//    #endif
    
    // --- INITIALIZATION ---
    init() {
        // Check if we are already logged in when the app starts
        if KeychainHelper.standard.read() != nil {
            print("🔑 Token found in Keychain. Validating...")
            self.isAuthenticated = true
            // Optional: You could verify the token with the backend here
        }
    }
    
    // --- 1. REGISTER (THE GOLDEN TICKET) ---
    func register(email: String, password: String, inviteCode: String) {
        self.isLoading = true
        self.errorMessage = ""
        
        guard let url = URL(string: "\(baseURL)/register/") else { return }
        
        let body: [String: Any] = [
            "email": email, // Backend now looks for this
            "password": password,
            "invite_code": inviteCode
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Connection failed: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Server error"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    // SUCCESS!
                    self.handleSuccess(data: data)
                } else if httpResponse.statusCode == 403 {
                    // BLOCKED BY BOUNCER
                    self.errorMessage = "🚫 Invalid or Expired Invite Code."
                } else {
                    self.errorMessage = "Registration failed. Username might be taken."
                }
            }
        }.resume()
    }
    
    // --- 2. LOGIN (STANDARD) ---
    func login(email: String, password: String) {
        self.isLoading = true
        self.errorMessage = ""
        
        guard let url = URL(string: "\(baseURL)/login/") else { return }
        
        let body: [String: Any] = [
            "username": email, // ⚠️ IMPORTANT: Django Login still expects the key "username", so we send the email here.
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Connection Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.handleSuccess(data: data)
                } else {
                    self.errorMessage = "Invalid username or password."
                }
            }
        }.resume()
    }
    
    // --- 3. LOGOUT ---
    func logout() {
        KeychainHelper.standard.delete()
        self.isAuthenticated = false
    }
    
    // --- HELPER: HANDLE SUCCESSFUL RESPONSE ---
    private func handleSuccess(data: Data?) {
        guard let data = data else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access"] as? String {
                
                // 1. Save to Keychain
                KeychainHelper.standard.save(token: token)
                
                // 2. Update State
                self.isAuthenticated = true
                print("🎉 Auth Success! Token saved.")
            }
        } catch {
            self.errorMessage = "Failed to parse token."
        }
    }
}
