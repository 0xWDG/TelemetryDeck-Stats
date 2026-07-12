//
//  ContentView.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI
struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient

    var body: some View {
        if apiClient.isAuthenticated {
            MainView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient.preview)
}
