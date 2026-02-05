//
//  ManifestMeApp.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

import SwiftUI

@main
struct ManifestMeApp: App {
    // This variable "remembers" if we are logged in
    // For now, it defaults to false.
    @State private var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView()
                    .transition(.opacity) // Smooth fade in
            } else {
                // We pass the "isLoggedIn" switch to the LoginView
                // so the LoginView can flip it when successful!
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}
