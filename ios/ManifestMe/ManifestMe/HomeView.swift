//
//  HomeView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

struct HomeView: View {
    
    // We can use this to control dark mode for the whole app if we want
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
    }

    var body: some View {
        TabView {
            // Tab 1: The New Screen
            CreateView()
                .tabItem {
                    Label("Create", systemImage: "wand.and.stars")
                }
            
            // Tab 2: Gallery (Placeholder)
            Text("My Videos")
                .tabItem {
                    Label("Gallery", systemImage: "photo.stack")
                }
            
            // Tab 3: Profile (Placeholder)
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        // Force dark mode for the tab bar look
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView()
}
