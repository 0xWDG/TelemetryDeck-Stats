//
//  LoginView.swift
//  TelemetrydeckViewer
//
//  Created by Telemetrydeck Viewer
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("TelemetryDeck Viewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("View and interact with your TelemetryDeck data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Login Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(isLoading)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .disabled(isLoading)
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canLogin ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!canLogin || isLoading)
            }
            .padding(.horizontal, 40)
            
            // Help Text
            VStack(spacing: 8) {
                Text("Don't have an account?")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Link("Sign up at TelemetryDeck.com", destination: URL(string: "https://telemetrydeck.com")!)
                    .font(.footnote)
                
                Link("API Documentation", destination: URL(string: "https://telemetrydeck.com/docs/api/")!)
                    .font(.footnote)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: 600)
        .padding()
        .task(autoLogin)
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func autoLogin() {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            return
        }

        isLoading = true
        showError = false

        Task {
            do {
                try await apiClient.login(bearerToken: token)
                try await apiClient.fetchOrganizations()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }

    private func login() {
        isLoading = true
        showError = false
        
        Task {
            do {
                try await apiClient.login(
                    email: email,
                    password: password
                )
                // Fetch initial data after successful login
                try await apiClient.fetchOrganizations()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(APIClient())
}
