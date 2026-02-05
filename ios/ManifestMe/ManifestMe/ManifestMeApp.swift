//
//  ManifestMeApp.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

@main
struct ManifestMeApp: App {
    // We default to false, but we will check the keychain immediately in init()
    @State private var isLoggedIn: Bool
    
    init() {
        // 1. Check the vault
        let token = KeychainHelper.standard.read()
        
        // 2. Print the result to the console (Debug)
        if token != nil {
            print("🔍 DEBUG: Found token in Keychain! Logging in automatically.")
            _isLoggedIn = State(initialValue: true)
        } else {
            print("🔍 DEBUG: No token found. User must log in.")
            _isLoggedIn = State(initialValue: false)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView()
                    .overlay(alignment: .topTrailing) {
                        Button("Logout") {
                            print("👋 DEBUG: Logging out and deleting token.")
                            KeychainHelper.standard.delete()
                            isLoggedIn = false
                        }
                        .padding()
                        .tint(.red)
                    }
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
