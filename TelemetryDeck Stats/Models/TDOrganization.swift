//
//  TDOrganization.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    // MARK: - Organizations

    /// Fetch organizations for the current user
    func fetchOrganizations() async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        beginLoading()
        defer { endLoading() }

        let request = try authenticatedRequest(path: "v3/organizations", token: token)

        let (data, response) = try await URLSession.shared.data(for: request)

#if DEBUG
        print(
            "fetchOrganizations",
            "Request",
            request,
            "Data",
            String(data: data, encoding: .utf8) ?? "none",
            "HTTPResponse",
            response
        )
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let orgs = try JSONDecoder().decode([TDOrganization].self, from: data)

        organizations = orgs
        if selectedOrganization == nil, let first = orgs.first {
            selectedOrganization = first
        }
    }
}

struct TDOrganization: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let roleOrganizationPermissions: String
}
