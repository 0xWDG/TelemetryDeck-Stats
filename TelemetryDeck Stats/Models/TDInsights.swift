//
//  TDInsights.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    /// Fetch insights for a specific app
    func fetchInsights(
        appID: String = "1058BF03-D5EF-4177-A789-395813F5F47D",
        dataSource: String? = nil,
        offset: Int = 30
    ) async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        guard let dataSource = dataSource ?? apps?.namespace else {
            throw APIError.missingDataSource
        }

        beginLoading()
        defer { endLoading() }

        var request = try authenticatedRequest(path: "v4/query/tql", token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            TDInsightsQuery(appID: appID, dataSource: dataSource, offset: offset)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print(
            "fetchInsights",
            "Request", request,
            "Data", String(data: data, encoding: .utf8) ?? "none",
            "HTTPResponse", response
        )
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let rows = try TDInsights.decoder.decode([TDInsight].self, from: data)
        let fetchedInsights = TDInsights(
            result: TDInsightRow(rows: rows),
            calculationFinishedAt: Date.now.ISO8601Format()
        )

        print("fetchedInsights", fetchedInsights)
        insights = fetchedInsights
        insightsByAppID[appID] = fetchedInsights
    }

    /// Fetch users grouped by country for a specific app
    func fetchCountries(
        appID: String,
        dataSource: String? = nil,
        dimension: String = "TelemetryDeck.UserPreference.region",
        offset: Int = 30
    ) async throws {
        guard !isPreview else { return }

        guard let token = authToken else {
            throw APIError.notAuthenticated
        }

        guard let dataSource = dataSource ?? apps?.namespace else {
            throw APIError.missingDataSource
        }

        beginLoading()
        defer { endLoading() }

        var request = try authenticatedRequest(path: "v4/query/tql", token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            TDCountriesQuery(appID: appID, dataSource: dataSource, dimension: dimension, offset: offset)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
        print(
            "fetchCountries",
            "Request", request,
            "Data", String(data: data, encoding: .utf8) ?? "none",
            "HTTPResponse", response
        )
#endif

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }

        let buckets = try TDInsights.decoder.decode([TDCountryBucket].self, from: data)
        countriesByAppID[appID] = buckets.flatMap(\.result)
    }

}

struct TDInsights: Identifiable {
    let result: TDInsightRow
    let calculationFinishedAt: String

    var id: String { calculationFinishedAt }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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

        init(users: Int) {
            self.users = users
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            users = Int(try container.decode(Double.self, forKey: .users))
        }

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case users = "Users"
        }
    }
}
extension TDInsight: Codable { }

struct TDCountryInsight: Decodable, Identifiable {
    var id: String { countryCode }

    let countryCode: String
    let users: Int

    private enum CodingKeys: String, CodingKey {
        case countryCode
        case users = "Users"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? "Unknown"
        users = Int(try container.decode(Double.self, forKey: .users))
    }
}

private struct TDCountryBucket: Decodable {
    let result: [TDCountryInsight]
}

private struct TDInsightsQuery: Encodable {
    let aggregations = [TDAggregation(type: "userCount")]
    let dataSource: String
    let filter: TDFilter
    let granularity = "day"
    let queryType = "timeseries"
    let relativeIntervals: [TDRelativeInterval]
    let testMode = false

    init(appID: String, dataSource: String, offset: Int) {
        self.dataSource = dataSource
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

private struct TDCountriesQuery: Encodable {
    let aggregations = [TDAggregation(type: "userCount")]
    let dataSource: String
    let dimension: TDDimension
    let filter: TDFilter
    let granularity = "all"
    let metric = TDMetric(metric: "Users")
    let queryType = "topN"
    let relativeIntervals: [TDRelativeInterval]
    let testMode = false
    let threshold = 200

    init(appID: String, dataSource: String, dimension: String, offset: Int) {
        self.dataSource = dataSource
        self.dimension = TDDimension(dimension: dimension, outputName: "countryCode")
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

private struct TDDimension: Encodable {
    let dimension: String
    let outputName: String
    let outputType = "STRING"
    let type = "default"
}

private struct TDMetric: Encodable {
    let type = "numeric"
    let metric: String
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
