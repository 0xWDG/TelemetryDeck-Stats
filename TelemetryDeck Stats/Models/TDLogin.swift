//
//  TDLogin.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    // MARK: - Authentication

    /// Login with email and password
    func login(email: String, password: String) async throws {
        guard !isPreview else { return }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)v3/users/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let loginString = "\(email):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw APIError.authenticationFailed
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

#if DEBUG
        print("login", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.authenticationFailed
        }

        let loginResponse = try JSONDecoder().decode(TDLoginResponse.self, from: data)

        await MainActor.run {
            self.authToken = loginResponse.value
            self.currentUser = loginResponse.user

            Task {
                try? await fetchUserInfo()
            }
        }
    }

    /// Login with bearer token
    func login(bearerToken: String) async throws {
        guard !isPreview else { return }

        await MainActor.run {
            self.authToken = bearerToken
        }

        try await fetchUserInfo()
    }
}

struct TDLoginResponse: Codable {
    let createdAt: String
    let expiresAt: String
    let id: String
    let user: TDUser
    let value: String
}
