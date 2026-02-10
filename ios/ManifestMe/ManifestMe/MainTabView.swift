//
//  MainTabView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/9/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: The Creator
            ManifestPathView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Create")
                }
            
            // Tab 2: The Gallery (Your old HomeView logic)
            GalleryView()
                .tabItem {
                    Image(systemName: "play.rectangle.on.rectangle")
                    Text("My Videos")
                }
            
            // Tab 3: The Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.yellow) // Gold icons
        .preferredColorScheme(.dark)
    }
}
