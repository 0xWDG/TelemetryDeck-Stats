//
//  MainView.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI
import SwiftExtras

struct MainView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedApp: TDApp?

    var body: some View {
        NavigationStack {
            List {
                // User Section
                Section("Account") {
                    if let user = apiClient.currentUser {
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)

                                Text(user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let apps = apiClient.apps {
                                    let used = Float(apps.maxSignals) * apps.usagePercentage
#if DEBUG
                                    let _ = print(
                                        "M", apps.maxSignals,
                                        "%", apps.usagePercentage,
                                        "U", used
                                    )
#endif
                                    ProgressView(value: apps.usagePercentage)
                                    Text("Signals \(Int(used))/\(Int(apps.maxSignals)) (\(apps.usagePercentage)%)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        .padding(.vertical, 4)
                    } else {
                        ProgressView()
                            .controlSize(.extraLarge)
                    }
                }
                .contextMenu {
                    Button(
                        "Logout",
                        systemImage: "arrow.backward.circle.fill",
                        role: .destructive
                    ) {
                        apiClient.logout()
                    }
                }

                // Organizations Section
                ForEach(apiClient.organizations) { organization in
                    Section {
                        if let apps = apiClient.apps?.apps,
                           apiClient.selectedOrganization?.id == organization.id {
                            if apps.isEmpty {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Loading apps...")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                ForEach(apps) { app in
                                    NavigationLink {
                                        InsightsView(app: app)
                                    } label: {
                                        HStack {
                                            Image(
                                                systemName: app.settings.displayMode == "app" ? "apps.iphone": "globe"
                                            )
                                            Text(app.name)
                                        }
                                    }
                                }
                            }
                        } else {
                            ProgressView()
                                .controlSize(.extraLarge)
                        }
                    } header: {
                        HStack {
                            Text(organization.name)
                            Spacer()
                            Text(organization.roleOrganizationPermissions)
                                .font(.callout)
                                .padding(2)
                                .background { Color.gray.opacity(0.2) }
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                Section(footer: Text("TelemetryDeck Stats by Wesley de Groot.")) {
                    EmptyView()
                }
            }
            .navigationTitle("TelemetryDeck Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationLink {
                    SESettingsView(_changeLog: [], _acknowledgements: [])
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .refreshable {
            await fetchData()
        }
        .task {
            await fetchData()
        }
    }

    private func fetchData() async {
        // Load organizations on appear
        if apiClient.organizations.isEmpty {
            do {
                try await apiClient.fetchOrganizations()
            } catch {
                // Log error - in production, use proper logging system
#if DEBUG
                print("Error fetching organizations: \(error)")
#endif
            }
        }

        // fetchApps
        do {
            if let organizationID = apiClient.selectedOrganization?.id {
                try await apiClient.fetchApps(organizationID: organizationID)
            }

            // try await apiClient.runQuery(query: "")
        } catch {
            // Log error - in production, use proper logging system
#if DEBUG
            print("Error fetching runQuery: \(error)")
#endif
        }
    }
}

#Preview {
    MainView()
        .environmentObject(APIClient.preview)
}
