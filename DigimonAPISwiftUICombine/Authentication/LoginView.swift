//
//  LoginView.swift
//  DigimonAPISwiftUICombine
//
//  Created by Patrick Tung on 3/16/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(isSignUp ? "Create Account" : "Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Form
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Error message
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Buttons
            if isLoading {
                ProgressView()
            } else {
                Button(action: handleAuthentication) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
    
    // Handle sign in or sign up
    private func handleAuthentication() {
        guard !email.isEmpty, !password.isEmpty else {
            authService.errorMessage = "Please enter both email and password"
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            authService.errorMessage = "Please enter a valid email address"
            return
        }
        
        // Validate password length
        if password.count < 6 {
            authService.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        if isSignUp {
            print("Attempting to sign up with email: \(email)")
            authService.signUp(email: email, password: password) { success in
                isLoading = false
                if success {
                    print("Sign up successful in view")
                } else {
                    print("Sign up failed in view: \(self.authService.errorMessage ?? "Unknown error")")
                }
            }
        } else {
            print("Attempting to sign in with email: \(email)")
            authService.signIn(email: email, password: password) { success in
                isLoading = false
                if success {
                    print("Sign in successful in view")
                } else {
                    print("Sign in failed in view: \(self.authService.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
    
    // Validate email format using a simple regex
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
} 