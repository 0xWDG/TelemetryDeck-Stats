//
//  TDApps.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    /// Fetch apps for the selected organization
    func fetchApps(organizationID: String) async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)v3/organizations/\(organizationID)/")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print("fetchApps", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let fetchedApps = try JSONDecoder().decode(TDApps.self, from: data)

        print(fetchedApps)

        await MainActor.run {
            self.apps = fetchedApps
        }
    }
}

struct TDApps: Codable, Identifiable {
    let id: String
    let apps: [TDApp]
    let maxSignals: Int
    let billingModel: String
    let usagePercentage: Float
    let namespace: String
}

struct TDApp: Codable, Identifiable {
    let id: String
    let name: String
    let organizationID: String
    let settings: Settings
    let insightGroups: [TDInsightGroup]

    struct TDInsightGroup: Codable, Identifiable {
        let id: String
        let appID: String
        let insightIDs: [String]
        let order: Int
        let title: String
    }

    struct Settings: Codable {
        let displayMode: String
    }
}
