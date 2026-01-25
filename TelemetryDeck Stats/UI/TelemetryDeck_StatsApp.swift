//
//  TelemetryDeck_StatsApp.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 25/01/2026.
//

import SwiftUI

@main
struct TelemetryDeck_StatsApp: App {
    @StateObject private var apiClient = APIClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
        }
    }
}
