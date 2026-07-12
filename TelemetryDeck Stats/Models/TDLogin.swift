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

        beginLoading()
        defer { endLoading() }

        var request = try request(path: "v3/users/login")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data()

        let loginString = "\(email):\(password)"
        guard let loginData = loginString.data(using: .utf8) else {
            throw APIError.authenticationFailed
        }
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

#if DEBUG
        print(
            "login",
            "Request", request,
            "Data", String(data: data, encoding: .utf8) ?? "none",
            "HTTPResponse", response
        )
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.authenticationFailed
        }

        let loginResponse = try JSONDecoder().decode(TDLoginResponse.self, from: data)

        authToken = loginResponse.value
        currentUser = loginResponse.user
    }

    /// Login with bearer token
    func login(bearerToken: String) async throws {
        guard !isPreview else { return }

        authToken = bearerToken

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
