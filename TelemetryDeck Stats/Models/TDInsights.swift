//
//  TDInsights.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    /// Fetch insights for a specific app
    func fetchInsights(appID: String = "1058BF03-D5EF-4177-A789-395813F5F47D") async throws {
        guard !isPreview else { return }

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

        try? await Task.sleep(for: defaultTimeout)

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
