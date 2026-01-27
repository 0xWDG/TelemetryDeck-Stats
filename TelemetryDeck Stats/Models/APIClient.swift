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
class APIClient: ObservableObject {
    // MARK: - Properties

    @Published var isAuthenticated = false
    @Published var currentUser: TDUser?
    @Published var organizations: [TDOrganization] = []
    @Published var selectedOrganization: TDOrganization?
    @Published var apps: TDApps?
    @Published var insights: TDInsights?
    @Published var isLoading = false
    @Published var errorMessage: String?

    public var isPreview: Bool = false {
        didSet {
            isAuthenticated = isPreview
        }
    }

    internal let baseURL = "https://api.telemetrydeck.com/api/"
    internal let defaultTimeout: Duration = .seconds(0.5)
    internal var authToken: String? {
        didSet {
            // TODO: In production, store tokens securely in Keychain
            // See CONFIGURATION.md for keychain implementation examples
            // Current implementation uses UserDefaults for simplicity
            UserDefaults.standard.set(authToken, forKey: "token")
            isAuthenticated = authToken != nil
        }
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
        }

        isPreview = false
        isAuthenticated = false
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
        }
    }
}

