//
//  AuthenticationService.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/16/25.
//

import Foundation
import FirebaseAuth
import Combine

class AuthenticationService: ObservableObject {
    // Published properties for authentication state
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // Initialize and setup auth state listener
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            
            self?.errorMessage = nil
            completion(true)
        }
    }
    
    /// Create a new user with email and password
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Log the attempt
        print("Attempting to sign up with email: \(email)")
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                // Log detailed error information
                print("Firebase signup error: \(error)")
                
                // Cast to specific Firebase error type if possible
                let authError = error as NSError
                let errorCode = AuthErrorCode(_bridgedNSError: authError)?.code
                
                // Provide more specific error messages based on the error code
                switch errorCode {
                case .emailAlreadyInUse:
                    self?.errorMessage = "This email is already in use. Please try logging in instead."
                case .invalidEmail:
                    self?.errorMessage = "Please enter a valid email address."
                case .weakPassword:
                    self?.errorMessage = "Password is too weak. Please use at least 6 characters."
                case .networkError:
                    self?.errorMessage = "Network error. Please check your internet connection."
                default:
                    self?.errorMessage = error.localizedDescription
                }
                
                completion(false)
                return
            }
            
            // Log success
            print("Successfully created user: \(result?.user.uid ?? "unknown")")
            self?.errorMessage = nil
            completion(true)
        }
    }
    
    /// Sign out the current user
    func signOut() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Get the current user's ID
    var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Check if user is signed in
    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
} 
