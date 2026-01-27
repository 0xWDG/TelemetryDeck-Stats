//
//  InsightsView.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI
import Charts

struct ChartData: Identifiable {
    let day: Date
    let users: Int

    var id: Int { day.hashValue }
}

struct InsightsView: View {
    @EnvironmentObject var apiClient: APIClient
    let app: TDApp
    @State private var isLoading = false
    @State private var errorMessage: String?

    var data: [ChartData] {
        (apiClient.insights?.result.rows.map {
            ChartData(day: $0.timestamp, users: $0.result.Users)
        }) ?? []
    }

    let formatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        List {
            Chart {
                ForEach(data, id: \.day) {
                    BarMark(
                        x: .value("Date", $0.day),
                        y: .value("Users", $0.users)
                    )
                }
            }
            .padding()
            .overlay {
                if data.isEmpty {
                    VStack {
                        ProgressView()
                            .controlSize(.large)

                        Text("Loading")
                    }
                }
            }

            if !data.isEmpty {
                Section("Uses per day") {
                    ForEach(data) {
                        LabeledContent(
                            "\($0.day, formatter: formatter)",
                            value: $0.users,
                            format: .number
                        )
                    }
                }
            }

            if !data.isEmpty {
                Section("Statistics") {
                    LabeledContent(
                        "Total Users in period",
                        value: data.reduce(0) { $0 + $1.users },
                        format: .number
                    )
                    LabeledContent(
                        "Average Users per day",
                        value: Double(data.reduce(0) { $0 + $1.users }) / Double(data.count),
                        format: .number.precision(.fractionLength(0))
                    )
                    // Most active day
                    if let mostActiveDay = data.max(by: { $0.users < $1.users }) {
                        LabeledContent(
                            "Most active day",
                            value: "\(formatter.string(from: mostActiveDay.day)) (\(mostActiveDay.users) users)"
                        )
                    }
                }
            }
        }
        .navigationTitle(app.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(Image(systemName: app.settings.displayMode == "app" ? "apps.iphone": "globe")) \(app.name)")
            }
        }
        .refreshable {
            do {
                try await apiClient.fetchInsights(appID: app.id)
            } catch {
                print("Error", error)
            }
        }
        .task {
            do {
                try await apiClient.fetchInsights(appID: app.id)
            } catch {
                print("Error", error)
            }
        }
    }

    private func loadInsights() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await apiClient.fetchInsights(appID: app.id)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(
            app: TDApp(
                id: "preview-app-1",
                name: "Test App",
                organizationID: "preview-org-1",
                settings: .init(displayMode: "app"),
                insightGroups: []
            )
        )
        .environmentObject(APIClient.preview)
    }
}

