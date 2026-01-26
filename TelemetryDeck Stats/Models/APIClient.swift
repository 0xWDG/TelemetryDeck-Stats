//
//  APIClient.swift
//  TelemetrydeckViewer
//
//  Created by Telemetrydeck Viewer
//

import Foundation
import Combine

#if canImport(WidgetKit)
import WidgetKit
#endif

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

    private let baseURL = "https://api.telemetrydeck.com/api/"
    private var authToken: String? {
        didSet {
            // TODO: In production, store tokens securely in Keychain
            // See CONFIGURATION.md for keychain implementation examples
            // Current implementation uses UserDefaults for simplicity
            UserDefaults.standard.set(authToken, forKey: "token")
            isAuthenticated = authToken != nil
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Authentication

    /// Login with email and password
    func login(email: String, password: String) async throws {
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
        await MainActor.run {
            self.authToken = bearerToken
        }

        try await fetchUserInfo()
    }

    /// Logout
    func logout() {
        authToken = nil
        currentUser = nil
        organizations = []
        selectedOrganization = nil
        apps = nil
        insights = nil
    }

    // MARK: - User

    /// Fetch current user information
    func fetchUserInfo() async throws {
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

    // MARK: - Organizations

    /// Fetch organizations for the current user
    func fetchOrganizations() async throws {
        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)v3/organizations")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

#if DEBUG
        print("fetchOrganizations", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let orgs = try JSONDecoder().decode([TDOrganization].self, from: data)

        await MainActor.run {
            self.organizations = orgs
            if self.selectedOrganization == nil, let first = orgs.first {
                self.selectedOrganization = first
            }
        }
    }

    // MARK: - Apps
    func runQuery(query: String) async throws {
        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        //        let url = URL(string: "\(baseURL)v3/insights/EE5F65E8-A409-429B-8FCD-B9CB6AB41827/query/")!

        //624B60A4-73F2-4835-97BD-585A10BCD0A3/apps/1058BF03-D5EF-4177-A789-395813F5F47D/explore/playground#
        let url = URL(string: "\(baseURL)v3/query/calculate-async/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = """
            {
              "relativeInterval": {
                "beginningDate": {
                  "component": "day",
                  "offset": -30,
                  "position": "beginning"
                },
                "endDate": {
                  "component": "day",
                  "offset": 0,
                  "position": "end"
                }
              }
            }
            """.data(using: .utf8)

        request.httpBody = """
            {"queryType":"timeseries","granularity":"month","aggregations":[{"type":"eventCount","name":"Number of Signals"},{"type":"userCount","name":"Number of Users"}],"postAggregations":[{"type":"arithmetic","name":"Signals per User","fn":"/","fields":[{"type":"finalizingFieldAccess","name":"_signals","fieldName":"Number of Signals"},{"type":"finalizingFieldAccess","name":"_users","fieldName":"Number of Users"}]}],"baseFilters":"thisOrganization","dataSource":"nl.wesleydegroot","sampleFactor":1000,"relativeIntervals":[{"beginningDate":{"component":"day","offset":-30,"position":"beginning"},"endDate":{"component":"day","offset":0,"position":"end"}}],"testMode":false}
            """.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print("runQuery", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("runQuery", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
            throw APIError.requestFailed
        }

        //
        let taskId = try JSONDecoder().decode(TDTaskId.self, from: data)

        try? await Task.sleep(for: .seconds(5))

        // Fetch data.
        let url2 = URL(string: "\(baseURL)v3/task/\(taskId.queryTaskID)/lastSuccessfulValue/")!
        var request2 = URLRequest(url: url2)
        request2.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data2, response2) = try await URLSession.shared.data(for: request2)
#if DEBUG
        print("runQuery", "Request2", request2, "Data", String(data: data2, encoding: .utf8), "HTTPResponse", response2)
#endif

        guard let httpResponse = response2 as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
    }

    /// Fetch apps for the selected organization
    func fetchApps(organizationID: String) async throws {
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

// MARK: - Models
struct TDLoginResponse: Codable {
    let createdAt: String
    let expiresAt: String
    let id: String
    let user: TDUser
    let value: String
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

struct TDTaskId: Codable, Identifiable {
    var id: Int { queryTaskID.hashValue }
    let queryTaskID: String
}

struct TDOrganization: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
}

/*
 {
 "apps": [{
 "id": "1058BF03-D5EF-4177-A789-395813F5F47D",
 "insightGroups": [{
 "appID": "1058BF03-D5EF-4177-A789-395813F5F47D",
 "id": "13AAD2D7-CF51-4569-AC3A-B9E0899A1231",
 "insightIDs": ["AFDCF376-DCE8-47F6-85ED-E6B3BDCE9286"],
 "order": 0,
 "title": "Errors"
 }],
 "name": "Disney Dreamlight Valley Guide",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app",
 "showExampleData": false
 }
 }, {
 "id": "73263699-B804-40E9-9150-14A5FE2AA287",
 "insightGroups": [],
 "name": "Wesley de Groot Website",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "colorScheme": "default",
 "displayMode": "website"
 }
 }, {
 "id": "37915BAE-A736-4FD4-986B-C2B79E805780",
 "insightGroups": [],
 "name": "Calendo",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app"
 }
 }, {
 "id": "82316827-5B57-42E1-8F92-CECACDD4A2DE",
 "insightGroups": [],
 "name": "iWebTools",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app"
 }
 }, {
 "id": "3D3ABC46-BDA7-47F5-A641-2E728694C79B",
 "insightGroups": [],
 "name": "Quacky.nl",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "website"
 }
 }, {
 "id": "B7D1AB35-471A-49FF-8A59-59573748044E",
 "insightGroups": [],
 "name": "Surprise Route",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app"
 }
 }, {
 "id": "8ABE528F-77A8-459C-BBED-37BF1E11D09A",
 "insightGroups": [],
 "name": "HexConquest",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app"
 }
 }, {
 "id": "D6D37874-E33A-4C62-9F43-DABC1AF5F24D",
 "insightGroups": [],
 "name": "Hot-Jake",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "website"
 }
 }, {
 "id": "B3F2A935-E51E-4B33-9847-1C4666658AD7",
 "insightGroups": [],
 "name": "Workout Route",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "app"
 }
 }, {
 "id": "6EBB2F2F-A892-4479-90AD-2EB655C05CDC",
 "insightGroups": [],
 "name": "Infinyte",
 "organizationID": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "settings": {
 "displayMode": "website"
 }
 }],
 "basePermissions": "write",
 "billingModel": "unpaid",
 "countryCode": "NL",
 "createdAt": "2022-02-04T22:24:18+0000",
 "id": "624B60A4-73F2-4835-97BD-585A10BCD0A3",
 "isInRestrictedMode": false,
 "isSuperOrg": false,
 "maxSignals": 100000,
 "metadata": {
 "referralSource": "Friend or colleague",
 "referralSourceUpdatedAt": "2025-09-18T05:10:29+0000"
 },
 "name": "WDGWV",
 "namespace": "nl.wesleydegroot",
 "referralCode": "0XL7FMWOV3LYPR61",
 "roleOrganizationPermissions": "administrate",
 "settings": {
 "ingestMode": "reindex",
 "namespaceConversionLastTaskID": "reindex_initial_nl.wesleydegroot_2022-12-11T00:00:00.000Z-2023-01-10T00:00:00.000Z_oxkq7vfys7vg",
 "namespaceConversionStatus": "completed",
 "namespaceShouldBeCompacted": true,
 "useNamespace": true
 },
 "usagePercentage": 0.10912
 }
 */

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


/* STATS
 curl 'https://api.telemetrydeck.com/api/v3/query/calculate-async/' \
 -X 'POST' \
 -H 'Content-Type: application/json' \
 -H 'Accept: application/json' \
 -H 'Authorization: Bearer 67KUM1E47YO7M0Q9KHYH329JNUAJA636QOLD34L08GYBFAQ63IFR34C9EKC6RPNAO7UD5TNMRKABTQ0KTUUYGIPV440QU3GZLJNO7GP0NJ3AO02I382Y9AZ0LLN8PQX2' \
 -H 'Sec-Fetch-Site: same-site' \
 -H 'Accept-Language: nl-NL,nl;q=0.9' \
 -H 'Accept-Encoding: gzip, deflate, br' \
 -H 'Sec-Fetch-Mode: cors' \
 -H 'Origin: https://dashboard.telemetrydeck.com' \
 -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15' \
 -H 'Content-Length: 470' \
 -H 'Sec-Fetch-Dest: empty' \
 -H 'Priority: u=3, i' \
 -H 'td-organization-id: nl.wesleydegroot' \
 --data-raw '{"dataSource":"nl.wesleydegroot","aggregations":[{"type":"userCount"}],"filter":{"type":"and","fields":[{"type":"selector","dimension":"appID","value":"1058BF03-D5EF-4177-A789-395813F5F47D"},{"type":"selector","dimension":"isTestMode","value":"false"}]},"granularity":"day","queryType":"timeseries","relativeIntervals":[{"beginningDate":{"component":"day","offset":-30,"position":"beginning"},"endDate":{"component":"day","offset":0,"position":"end"}}],"testMode":false}'

 ....

 result:
 {
 "calculationDuration": 0.06190061569213867,
 "calculationFinishedAt": "2026-01-25T21:22:20+0000",
 "result": {
 "rows": [
    {
    "result": {
        "Users": 27
    },
    "timestamp": "2025-12-26T00:00:00+0000"
 },
 ....
 // */

struct TDInsights: Codable, Identifiable {
    let result: TDInsightRow
    let calculationFinishedAt: String

    var id: Int { calculationFinishedAt.hashValue }
}

struct TDInsightRow: Codable, Identifiable {
    let rows: [TDInsight]

    var id: Int { rows.count.hashValue }
}

struct TDInsight: Codable, Identifiable {
    var id: Int { timestamp.hashValue }

    let result: TDInsightResult
    let timestamp: Date

    struct TDInsightResult: Codable {
        let Users: Int
    }
}

extension APIClient {
    // MARK: - Insights

    /// Fetch insights for a specific app
    func fetchInsights(appID: String = "1058BF03-D5EF-4177-A789-395813F5F47D") async throws {
        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)v3/query/calculate-async/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // "dataSource":"nl.wesleydegroot",
        request.httpBody = """
         {"aggregations":[{"type":"userCount"}],"filter":{"type":"and","fields":[{"type":"selector","dimension":"appID","value":"\(appID)"},{"type":"selector","dimension":"isTestMode","value":"false"}]},"granularity":"day","queryType":"timeseries","relativeIntervals":[{"beginningDate":{"component":"day","offset":-30,"position":"beginning"},"endDate":{"component":"day","offset":0,"position":"end"}}],"testMode":false}    
        """.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print("fetchInsights", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let taskId = try JSONDecoder().decode(TDTaskId.self, from: data)
        print(taskId)

        try? await Task.sleep(for: .seconds(5))

        // Fetch data...
        let url2 = URL(string: "\(baseURL)v3/task/\(taskId.queryTaskID)/lastSuccessfulValue/")!
        var request2 = URLRequest(url: url2)
        request2.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data2, response2) = try await URLSession.shared.data(for: request2)
#if DEBUG
        print("runQuery", "Request2", request2, "Data", String(data: data2, encoding: .utf8), "HTTPResponse", response2)
#endif

        guard let httpResponse = response2 as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        let fetchedInsights = try decoder.decode(TDInsights.self, from: data2)
        print("fetchedInsights", fetchedInsights)

        await MainActor.run {
            self.insights = fetchedInsights
        }
    }
}

// MARK: - Widget Data Model

///// Data structure for sharing widget information between app and widget
//struct TDWidgetData: Codable {
//    let appName: String
//    let insightTitle: String
//    let value: String
//    let change: String?
//}
//
//// MARK: - Widget Support
//
//extension APIClient {
//    /// Save widget data to shared container for widget to access
//    func saveWidgetData(appName: String, insightTitle: String, value: String, change: String?) {
//        let widgetData = TDWidgetData(
//            appName: appName,
//            insightTitle: insightTitle,
//            value: value,
//            change: change
//        )
//
//        if let encoded = try? JSONEncoder().encode(widgetData) {
//            UserDefaults(suiteName: "group.telemetrydeck.viewer")?.set(encoded, forKey: "widgetData")
//        } else {
//            // Log encoding failure in debug builds
//#if DEBUG
//            print("Failed to encode widget data")
//#endif
//        }
//    }
//
//    /// Fetch insight data and update widget
//    func updateWidgetData(for app: TDApp, insight: TDInsight) async {
//        // In a real implementation, you would fetch the actual insight data
//        // For now, we'll use placeholder values
//        let value = generateMockValue(for: insight)
//        let change = generateMockChange()
//
//        saveWidgetData(
//            appName: app.name,
//            insightTitle: insight.title,
//            value: value,
//            change: change
//        )
//
//        // Reload all widget timelines
//#if canImport(WidgetKit)
//        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
//#endif
//    }
//
//    private func generateMockValue(for insight: TDInsight) -> String {
//        // Generate mock values based on display mode
//        switch insight.displayMode {
//        case "number":
//            return "\(Int.random(in: 100...9999))"
//        case "barChart", "lineChart":
//            let value = Double.random(in: 100...10000)
//            if value > 1000 {
//                return String(format: "%.1fK", value / 1000)
//            }
//            return "\(Int(value))"
//        default:
//            return "\(Int.random(in: 100...9999))"
//        }
//    }
//
//    private func generateMockChange() -> String? {
//        let change = Int.random(in: -20...30)
//        if change == 0 { return nil }
//        return change > 0 ? "+\(change)%" : "\(change)%"
//    }
//}

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

// MARK: - Preview Support

#if DEBUG
extension APIClient {
    /// Creates a preview APIClient with mock data for SwiftUI previews
    static var preview: APIClient {
        let client = APIClient()
        client.isAuthenticated = true
        client.currentUser = TDUser(
            id: "preview-user-1",
            email: "demo@example.com",
            firstName: "Demo",
            lastName: "User"
        )
        client.organizations = [
            TDOrganization(
                id: "preview-org-1",
                name: "My Organization",
                description: "A demo organization"
            ),
            TDOrganization(
                id: "preview-org-2",
                name: "Second Company",
                description: "Another organization"
            )
        ]
        client.selectedOrganization = client.organizations.first
        client.apps = TDApps(
            id: "0",
            apps: [
                TDApp(
                    id: "preview-app-1",
                    name: "iOS App",
                    organizationID: "preview-org-1",
                    settings: .init(displayMode: "app"),
                    insightGroups: []
                ),
                TDApp(
                    id: "preview-app-2",
                    name: "Web App",
                    organizationID: "preview-org-1",
                    settings: .init(displayMode: "app"),
                    insightGroups: []
                ),
                TDApp(
                    id: "preview-app-3",
                    name: "Android App",
                    organizationID: "preview-org-1",
                    settings: .init(displayMode: "app"),
                    insightGroups: [])
            ],
            maxSignals: 1000,
            billingModel: "free",
            usagePercentage: 1.0,
            namespace: "nl.wesleydegroot.test"
        )

        client.insights = nil
//        client.insights = [
//            TDInsight(
//                id: "preview-insight-1",
//                title: "Active Users",
//                description: "Daily active users",
//                displayMode: "number"
//            ),
//            TDInsight(
//                id: "preview-insight-2",
//                title: "User Growth",
//                description: "User growth over time",
//                displayMode: "lineChart"
//            ),
//            TDInsight(
//                id: "preview-insight-3",
//                title: "Platform Distribution",
//                description: "Users by platform",
//                displayMode: "pieChart"
//            ),
//            TDInsight(
//                id: "preview-insight-4",
//                title: "Revenue Trend",
//                description: "Monthly revenue",
//                displayMode: "barChart"
//            )
//        ]
        return client
    }
}
#endif
