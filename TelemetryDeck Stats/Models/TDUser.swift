//
//  TDUser.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    // MARK: - User

    /// Fetch current user information
    func fetchUserInfo() async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)v3/users/info")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

#if DEBUG
        print("fetchUserInfo", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let user = try JSONDecoder().decode(TDUser.self, from: data)

        await MainActor.run {
            self.currentUser = user
        }
    }
}

struct TDUser: Codable, Identifiable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        }
        return email ?? "User"
    }
}
