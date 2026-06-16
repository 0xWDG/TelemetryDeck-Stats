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

    var id: Date { day }
}

struct InsightsView: View {
    @EnvironmentObject var apiClient: APIClient
    let app: TDApp
    @State private var errorMessage: String?
    @State private var selection: String = "Visitors"

    var body: some View {
        let data = chartData
        let stats = chartStats(for: data)

        List {
            Chart {
                ForEach(data) {
                    BarMark(
                        x: .value("Date", $0.day, unit: .day),
                        y: .value("Users", $0.users)
                    )
                }
            }
            .padding()
            .overlay {
                if data.isEmpty || apiClient.isLoading {
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
                            $0.day.formatted(date: .abbreviated, time: .omitted),
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
                        value: stats.totalUsers,
                        format: .number
                    )
                    LabeledContent(
                        "Average Users per day",
                        value: stats.averageUsers,
                        format: .number.precision(.fractionLength(0))
                    )
                    // Most active day
                    if let mostActiveDay = stats.mostActiveDay {
                        LabeledContent(
                            "Most active day",
                            value: "\(mostActiveDay.day.formatted(date: .abbreviated, time: .omitted)) (\(mostActiveDay.users) users)"
                        )
                    }
                }
            }

            if let errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(Image(systemName: app.settings.displayMode == "app" ? "apps.iphone": "globe")) \(app.name)")
            }
        }
        .safeAreaInset(edge: .top) {
            Picker("Select app", selection: $selection) {
                Text("Visitors").tag("Visitors")
                Text("Countries").tag("Countries")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .disabled(data.isEmpty || apiClient.isLoading)
        }
        .refreshable {
            await fetchInsights()
        }
        .task(id: app.id) {
            await fetchInsights()
        }
    }

    private var chartData: [ChartData] {
        apiClient.insights(for: app.id)?.result.rows.map {
            ChartData(day: $0.timestamp, users: $0.result.users)
        } ?? []
    }

    private func chartStats(for data: [ChartData]) -> ChartStats {
        let totalUsers = data.reduce(0) { $0 + $1.users }
        return ChartStats(
            totalUsers: totalUsers,
            averageUsers: data.isEmpty ? 0 : Double(totalUsers) / Double(data.count),
            mostActiveDay: data.max { $0.users < $1.users }
        )
    }

    private func fetchInsights() async {
        do {
            try await apiClient.fetchInsights(appID: app.id)
            errorMessage = nil
        } catch {
#if DEBUG
            print("Error", error)
#endif
            errorMessage = error.localizedDescription
        }
    }
}

private struct ChartStats {
    let totalUsers: Int
    let averageUsers: Double
    let mostActiveDay: ChartData?
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
