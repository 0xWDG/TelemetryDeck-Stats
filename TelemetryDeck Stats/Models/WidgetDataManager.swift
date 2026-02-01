//
//  WidgetDataManager.swift
//  TelemetryDeck Stats
//
//  Manages data sharing between the main app and widget
//

import Foundation
import WidgetKit

extension APIClient {
    /// Update widget data for a specific app after fetching insights
    /// This should be called after fetchInsights() for each app to update the widget
    func updateWidgetDataForApp(appID: String, offset: Int) async {
        guard let apps = self.apps else { return }
        
        // Calculate total users from insights
        let totalUsers = insights?.result.rows.reduce(0) { $0 + $1.result.Users } ?? 0
        
        // Load existing widget data
        var existingStats: [[String: Any]] = []
        if let sharedDefaults = UserDefaults(suiteName: "group.nl.wesleydegroot.TelemetryDeckStats"),
           let savedData = sharedDefaults.data(forKey: "widgetData"),
           let widgetData = try? JSONSerialization.jsonObject(with: savedData) as? [String: Any],
           let stats = widgetData["stats"] as? [[String: Any]] {
            existingStats = stats
        }
        
        // Update or add the app's statistics
        if let index = existingStats.firstIndex(where: { ($0["id"] as? String) == appID }) {
            existingStats[index]["value"] = totalUsers
        } else {
            if let app = apps.apps.first(where: { $0.id == appID }) {
                existingStats.append([
                    "id": app.id,
                    "name": app.name,
                    "value": totalUsers,
                    "displayMode": app.settings.displayMode
                ])
            }
        }
        
        // Create updated widget entry
        let entry: [String: Any] = [
            "date": Date().timeIntervalSince1970,
            "stats": existingStats,
            "configuration": [
                "timePeriod": offset == 1 ? "Today" : "Last 30 Days",
                "hiddenAppIDs": []
            ] as [String: Any]
        ]
        
        // Save to shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.nl.wesleydegroot.TelemetryDeckStats") {
            if let jsonData = try? JSONSerialization.data(withJSONObject: entry) {
                sharedDefaults.set(jsonData, forKey: "widgetData")
                
                // Request widget refresh
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

// MARK: - Widget Data Models (for app use)

struct WidgetStatistic: Codable, Identifiable {
    let id: String
    let name: String
    var value: Int
    let displayMode: String
}
