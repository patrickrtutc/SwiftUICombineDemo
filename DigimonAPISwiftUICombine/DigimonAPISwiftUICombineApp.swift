//
//  DigimonAPISwiftUICombineApp.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/4/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct DigimonApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Create a shared repository
    private let repository = DefaultDigimonRepository()
    
    // Create view model with the repository
    @StateObject private var viewModel = SearchableDigimonListView.ViewModel(
        repository: DefaultDigimonRepository()
    )
    
    var body: some Scene {
        WindowGroup {
            // Use AuthenticationContainerView as the root view
            AuthenticationContainerView()
                .environmentObject(viewModel)
                .onAppear {
                    // Pre-fetch data when app launches
                    viewModel.fetchDigimons()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase with logging enabled
            FirebaseApp.configure()
            print("Firebase successfully configured")
            
            // Check if Auth is configured
            if Auth.auth().app != nil {
                print("Firebase Auth is properly initialized")
            } else {
                print("WARNING: Firebase Auth is not properly initialized")
        }
        return true
    }
}
