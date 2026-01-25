//
//  InsightsView.swift
//  TelemetrydeckViewer
//
//  Created by Telemetrydeck Viewer
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var apiClient: APIClient
    let app: TDApp
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading insights...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error Loading Insights")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadInsights()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if apiClient.insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No Insights Available")
                        .font(.headline)
                    Text("This app doesn't have any insights yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(apiClient.insights) { insight in
                        InsightRowView(insight: insight, app: app)
                            .environmentObject(apiClient)
                    }
                }
                .navigationTitle(app.name)
                .refreshable {
                    loadInsights()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: loadInsights) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            loadInsights()
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

struct InsightRowView: View {
    @EnvironmentObject var apiClient: APIClient
    let insight: TDInsight
    let app: TDApp
    @State private var showingPinConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.blue)
                Text(insight.title)
                    .font(.headline)
                
                Spacer()
                
                // Pin to Widget button
                Button(action: {
                    pinToWidget()
                }) {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Circle().fill(Color.orange.opacity(0.2)))
                }
                .buttonStyle(.plain)
            }
            
            if let description = insight.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let displayMode = insight.displayMode {
                Text("Display: \(displayMode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .alert("Pinned to Widget", isPresented: $showingPinConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("'\(insight.title)' has been pinned to your home screen widget.")
        }
    }
    
    private func pinToWidget() {
        Task {
            await apiClient.updateWidgetData(for: app, insight: insight)
            await MainActor.run {
                showingPinConfirmation = true
            }
        }
    }
    
    private var iconName: String {
        switch insight.displayMode {
        case "barChart", "bar":
            return "chart.bar.fill"
        case "lineChart", "line":
            return "chart.line.uptrend.xyaxis"
        case "pieChart", "pie":
            return "chart.pie.fill"
        case "number":
            return "number.circle.fill"
        default:
            return "chart.xyaxis.line"
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
