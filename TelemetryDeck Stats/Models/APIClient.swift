//
//  APIClient.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import Foundation
import Combine

/// API Client for interacting with TelemetryDeck API
/// API Documentation: https://telemetrydeck.com/docs/api/
@MainActor
class APIClient: ObservableObject {
    // MARK: - Properties

    @Published var isAuthenticated = false
    @Published var currentUser: TDUser?
    @Published var organizations: [TDOrganization] = []
    @Published var selectedOrganization: TDOrganization?
    @Published var apps: TDApps?
    @Published var insights: TDInsights?
    @Published var insightsByAppID: [String: TDInsights] = [:]
    @Published var countriesByAppID: [String: [TDCountryInsight]] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    public var isPreview: Bool = false {
        didSet {
            isAuthenticated = isPreview
        }
    }

    internal let baseURL: URL
    internal let defaultTimeout: Duration = .seconds(0.5)
    private let tokenStore: TokenStoring
    private var activeRequestCount = 0

    internal var authToken: String? {
        didSet {
            do {
                try tokenStore.saveToken(authToken)
            } catch {
#if DEBUG
                print("Failed to save token: \(error)")
#endif
            }
            isAuthenticated = authToken != nil
        }
    }

    init(
        tokenStore: TokenStoring = KeychainTokenStore(),
        baseURL: URL = URL(string: "https://api.telemetrydeckapi.com/api/") ?? URL(fileURLWithPath: "/")
    ) {
        self.tokenStore = tokenStore
        self.baseURL = baseURL
        self.authToken = tokenStore.readToken()
        self.isAuthenticated = authToken != nil
    }

    /// Logout
    func logout() {
        if !isPreview {
            authToken = nil
            currentUser = nil
            organizations = []
            selectedOrganization = nil
            apps = nil
            insights = nil
            insightsByAppID = [:]
            countriesByAppID = [:]
        }

        isPreview = false
        isAuthenticated = false
    }

    func savedToken() -> String? {
        tokenStore.readToken()
    }

    func insights(for appID: String) -> TDInsights? {
        insightsByAppID[appID]
    }

    func countries(for appID: String) -> [TDCountryInsight] {
        countriesByAppID[appID] ?? []
    }

    internal func authenticatedRequest(path: String, token: String) throws -> URLRequest {
        var request = try request(path: path)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    internal func request(path: String) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw APIError.invalidURL
        }

        return URLRequest(url: url)
    }

    internal func beginLoading() {
        activeRequestCount += 1
        isLoading = true
    }

    internal func endLoading() {
        activeRequestCount = max(activeRequestCount - 1, 0)
        isLoading = activeRequestCount > 0
    }
}

// MARK: - Models
struct TDTaskId: Codable, Identifiable {
    var id: Int { queryTaskID.hashValue }
    let queryTaskID: String
}

// MARK: - Errors
enum APIError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case requestFailed
    case decodingFailed
    case invalidURL
    case missingDataSource

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        case .requestFailed:
            return "Request failed. Please try again."
        case .decodingFailed:
            return "Failed to decode response."
        case .invalidURL:
            return "The API request URL is invalid."
        case .missingDataSource:
            return "The TelemetryDeck data source is unavailable. Refresh your organizations and try again."
        }
    }
}
