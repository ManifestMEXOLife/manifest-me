//
//  HomeView.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            // Tab 1: Create
            VStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                Text("Manifest New Video")
                    .font(.title2)
                    .bold()
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle.fill")
            }
            
            // Tab 2: Gallery
            Text("My Videos")
                .tabItem {
                    Label("Gallery", systemImage: "photo.stack")
                }
            
            // Tab 3: Profile
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    HomeView()
}
