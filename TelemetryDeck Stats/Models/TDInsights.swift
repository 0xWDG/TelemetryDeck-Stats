//
//  TDInsights.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    /// Fetch insights for a specific app
    func fetchInsights(appID: String = "1058BF03-D5EF-4177-A789-395813F5F47D", offset: Int = 30) async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        beginLoading()
        defer { endLoading() }

        var request = try authenticatedRequest(path: "v3/query/calculate-async/", token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(TDInsightsQuery(appID: appID, offset: offset))

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print("fetchInsights", "Request", request, "Data", String(data: data, encoding: .utf8), "HTTPResponse", response)
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let taskId = try JSONDecoder().decode(TDTaskId.self, from: data)

        try? await Task.sleep(for: defaultTimeout)

        let fetchedInsights: TDInsights = try await retry(timeout: .seconds(1)) {
            let request2 = try authenticatedRequest(
                path: "v3/task/\(taskId.queryTaskID)/lastSuccessfulValue/",
                token: token
            )
            let (data2, response2) = try await URLSession.shared.data(for: request2)
#if DEBUG
            print("runQuery", "Request2", request2, "Data", String(data: data2, encoding: .utf8), "HTTPResponse", response2)
#endif

            guard let httpResponse = response2 as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.requestFailed
            }

            return try TDInsights.decoder.decode(TDInsights.self, from: data2)
        }

        print("fetchedInsights", fetchedInsights)
        insights = fetchedInsights
        insightsByAppID[appID] = fetchedInsights
    }

    private func retry<T>(
        maxRetryCount: Int = 3,
        timeout: Duration,
        operation: () async throws -> T
    ) async throws -> T {
        for _ in 0 ..< maxRetryCount {
            try Task<Never, Never>.checkCancellation()

            do {
                return try await operation()
            } catch {
                try await Task<Never, Never>.sleep(for: timeout)
            }
        }

        try Task<Never, Never>.checkCancellation()
        return try await operation()
    }
}

struct TDInsights: Identifiable {
    let result: TDInsightRow
    let calculationFinishedAt: String

    var id: String { calculationFinishedAt }

    static var decoder: JSONDecoder {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}
extension TDInsights: Codable { }

struct TDInsightRow: Identifiable {
    let rows: [TDInsight]

    var id: Int { rows.count.hashValue }
}
extension TDInsightRow: Codable { }

struct TDInsight: Identifiable {
    var id: Date { timestamp }

    let result: TDInsightResult
    let timestamp: Date

    struct TDInsightResult: Codable {
        let users: Int

        enum CodingKeys: String, CodingKey {
            case users = "Users"
        }
    }
}
extension TDInsight: Codable { }

private struct TDInsightsQuery: Encodable {
    let aggregations = [TDAggregation(type: "userCount")]
    let filter: TDFilter
    let granularity = "day"
    let queryType = "timeseries"
    let relativeIntervals: [TDRelativeInterval]
    let testMode = false

    init(appID: String, offset: Int) {
        filter = TDFilter(fields: [
            TDSelectorFilter(dimension: "appID", value: appID),
            TDSelectorFilter(dimension: "isTestMode", value: "false")
        ])
        relativeIntervals = [
            TDRelativeInterval(
                beginningDate: TDRelativeDate(component: "day", offset: -offset, position: "beginning"),
                endDate: TDRelativeDate(component: "day", offset: 0, position: "end")
            )
        ]
    }
}

private struct TDAggregation: Encodable {
    let type: String
}

private struct TDFilter: Encodable {
    let type = "and"
    let fields: [TDSelectorFilter]
}

private struct TDSelectorFilter: Encodable {
    let type = "selector"
    let dimension: String
    let value: String
}

private struct TDRelativeInterval: Encodable {
    let beginningDate: TDRelativeDate
    let endDate: TDRelativeDate
}

private struct TDRelativeDate: Encodable {
    let component: String
    let offset: Int
    let position: String
}
