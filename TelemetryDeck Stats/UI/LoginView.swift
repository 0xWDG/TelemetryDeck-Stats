//
//  LoginView.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI
import SwiftExtras

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
                AppInfo
                    .appIcon
                    .cornerRadius(24)
                    .frame(size: 124)

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
                .background(canLogin ? Color.accentColor : Color.gray)
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

                    Link("Sign up on TelemetryDeck.com", destination: URL(string: "https://dashboard.telemetrydeck.com/register")!)

                    Button("Sign in with demo account") {
                        apiClient.isPreview = true
                    }

            }
            .font(.footnote)
            .padding(.top, 20)

            Spacer()

            Text("""
TelemetryDeck Viewer is not affiliated with [TelemetryDeck GmbH](https://telemetrydeck.com/).
TelemetryDeck Viewer is built by [Wesley de Groot](https://wesleydegroot.nl).
""")
            .font(.footnote)
        }
        .padding()
        .background {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.systemBackground,
                    Color.accentColor.opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
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
