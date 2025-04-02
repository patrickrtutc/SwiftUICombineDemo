//
//  AuthenticationContainerView.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/16/25.
//

import SwiftUI

struct AuthenticationContainerView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                // Main app content
                TabView {
                    // Your existing main app view
                    SearchableDigimonListView()
                        .tabItem {
                            Label("Digimon", systemImage: "list.bullet")
                        }
                    
                    // Profile view
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                }
                .environmentObject(authService)
            } else {
                // Authentication view
                LoginView()
                    .environmentObject(authService)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
} 