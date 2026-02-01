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
    @State private var selection: String = "Visitors"
    @State private var timePeriod: TimePeriodOption = .last30Days
    
    enum TimePeriodOption: String, CaseIterable {
        case today = "Today"
        case last30Days = "Last 30 Days"
        
        var offset: Int {
            switch self {
            case .today: return 1
            case .last30Days: return 30
            }
        }
    }

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(Image(systemName: app.settings.displayMode == "app" ? "apps.iphone": "globe")) \(app.name)")
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                Picker("Time Period", selection: $timePeriod) {
                    ForEach(TimePeriodOption.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(data.isEmpty || apiClient.isLoading)
                .onChange(of: timePeriod) { _, newValue in
                    Task {
                        do {
                            try await apiClient.fetchInsights(appID: app.id, offset: newValue.offset)
                            await apiClient.updateWidgetDataForApp(appID: app.id, offset: newValue.offset)
                        } catch {
                            print("Error", error)
                        }
                    }
                }
                
                Picker("Select view", selection: $selection) {
                    Text("Visitors").tag("Visitors")
                    Text("Countries").tag("Countries")
                }
                .pickerStyle(.segmented)
                .disabled(data.isEmpty || apiClient.isLoading)
            }
            .padding(.horizontal)
        }
        .refreshable {
            do {
                try await apiClient.fetchInsights(appID: app.id, offset: timePeriod.offset)
                await apiClient.updateWidgetDataForApp(appID: app.id, offset: timePeriod.offset)
            } catch {
                print("Error", error)
            }
        }
        .onAppear {
            Task {
                do {
                    try await apiClient.fetchInsights(appID: app.id, offset: timePeriod.offset)
                    await apiClient.updateWidgetDataForApp(appID: app.id, offset: timePeriod.offset)
                } catch {
                    print("Error", error)
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

