//
//  ManifestMeApp.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

@main
struct ManifestMeApp: App {
    // 1. Create the single shared instance of our "Brain"
    // This automatically checks the Keychain when it initializes!
    @StateObject var authService = AuthService()
    @StateObject var videoService = VideoService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(videoService) // <--- Pass it down
                } else {
                    LoginView()
                }
            }
            .environmentObject(authService)
        }
    }
}
