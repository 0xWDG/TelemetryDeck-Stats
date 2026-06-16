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
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case email, password }
    
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
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Login Form
            VStack(spacing: 16) {
                VStack(spacing: 18) {
                    // Email field with icon
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disabled(isLoading)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Password field with icon
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .disabled(isLoading)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                login()
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if showError {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Button(action: login) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            Text(isLoading ? "Signing in…" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(canLogin ? .accentColor : .gray)
                    .disabled(!canLogin)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 12)
                )
            }
            .padding(.horizontal, 40)
            
            // Help Text
            VStack(spacing: 8) {
                Text("Don't have an account?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let registrationURL {
                    Link("Sign up on TelemetryDeck.com", destination: registrationURL)
                }

                Button("Sign in with demo account") {
                    apiClient.applyPreviewData()
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
        .onAppear {
            focusedField = .email
        }
    }
    
    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty && !isLoading
    }

    private var registrationURL: URL? {
        URL(string: "https://dashboard.telemetrydeck.com/register")
    }

    private func login() {
        guard canLogin else { return }

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
