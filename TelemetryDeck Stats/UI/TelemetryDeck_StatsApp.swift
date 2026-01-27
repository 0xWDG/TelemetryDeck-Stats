//
//  TelemetryDeck_StatsApp.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI

@main
struct TelemetryDeck_StatsApp: App {
    @StateObject private var apiClient = APIClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // support preview mode, it does not last after restart of the app.
                .environmentObject(apiClient.isPreview ? APIClient.preview : apiClient)
                // print automatic login (if possible)
                .task(autoLogin)
        }
    }

    func autoLogin() {
        guard let token = UserDefaults.standard.string(forKey: "token") else {
            return
        }

        Task {
            do {
                try? await apiClient.login(bearerToken: token)
                try? await apiClient.fetchOrganizations()
            }
        }
    }
}
