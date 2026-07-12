//
//  TelemetryDeckStats.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI

@main
struct TelemetryDeckStats: App {
    @StateObject private var apiClient = APIClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
                // print automatic login (if possible)
                .task(autoLogin)
        }
    }

    func autoLogin() async {
        guard let token = apiClient.savedToken() else {
            return
        }

        try? await apiClient.login(bearerToken: token)
        try? await apiClient.fetchOrganizations()
    }
}
