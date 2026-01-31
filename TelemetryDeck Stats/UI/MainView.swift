//
//  MainView.swift
//  Telemetrydeck Stats
//
//  Created by Wesley de Groot
//

import SwiftUI
import SwiftExtras
import CryptoKit

struct MainView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedApp: TDApp?
    
    var body: some View {
        NavigationStack {
            List {
                // Account Header Card
                Section {
                    if let user = apiClient.currentUser {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(.thinMaterial)
                                        .frame(width: 48, height: 48)
                                    if let email = user.email,
                                       let gravatarURL = getGravatarURL(for: email) {
                                        AsyncImage(url: gravatarURL) { phase in
                                            switch phase {
                                            case .empty:
                                                ZStack {
                                                    defaultProfileImage
                                                    ProgressView()
                                                }
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 48, height: 48)
                                                    .clipShape(Circle())
                                            case .failure:                                            
                                                defaultProfileImage
                                            @unknown default:
                                                defaultProfileImage
                                            }
                                        }
                                       }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(.title3.weight(.semibold))
                                    if let email = user.email, !email.isEmpty {
                                        Text(email)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            if let apps = apiClient.apps {
                                let used = Float(apps.maxSignals) * apps.usagePercentage
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Label("Usage", systemImage: "chart.bar.fill")
                                            .font(.subheadline.weight(.semibold))
                                            .labelStyle(.titleAndIcon)
                                        Spacer()
                                        Text("\(Int(used))/\(Int(apps.maxSignals))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    ProgressView(value: apps.usagePercentage) {
                                        EmptyView()
                                    } currentValueLabel: {
                                        Text("\(Int(apps.usagePercentage * 100))%")
                                            .font(.caption2)
                                            .monospacedDigit()
                                            .foregroundStyle(.secondary)
                                    }
                                    .tint(
                                        apps.usagePercentage > 0.9 ? .red :
                                            (apps.usagePercentage > 0.75 ? .purple : .accentColor)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.regular)
                            VStack(alignment: .leading) {
                                Text("Loading account")
                                    .font(.subheadline)
                                Text("Fetching your profile and usage…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Account")
                } footer: {
                    EmptyView()
                }
                .listRowBackground(
                    LinearGradient(colors: [Color(.secondarySystemBackground), Color(.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .opacity(0.8)
                )
                .contextMenu {
                    Button(
                        "Logout",
                        systemImage: "arrow.backward.circle.fill",
                        role: .destructive
                    ) {
                        apiClient.logout()
                    }
                }

                // Organizations and Apps
                ForEach(apiClient.organizations) { organization in
                    Section {
                        if let apps = apiClient.apps?.apps,
                           apiClient.selectedOrganization?.id == organization.id {
                            if apps.isEmpty {
                                HStack {
                                    ProgressView()
                                        .controlSize(.small)

                                    Text("Loading apps…")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                ForEach(apps) { app in
                                    NavigationLink {
                                        InsightsView(app: app)
                                    } label: {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.quaternary)
                                                    .frame(width: 34, height: 34)
                                                Image(systemName: app.settings.displayMode == "app" ? "apps.iphone" : "globe")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(app.name)
                                                    .font(.body)
                                                Text(app.settings.displayMode == "app" ? "Application" : "Website")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        } else {
                            HStack {
                                ProgressView().controlSize(.small)
                                Text("Loading…")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        HStack {
                            Text(organization.name)
                            Spacer()
                            Text(organization.roleOrganizationPermissions)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.gray.opacity(0.15))
                                )
                                .foregroundStyle(.primary)
                        }
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                }

                Section(footer: Text("TelemetryDeck Stats by Wesley de Groot.").font(.footnote).foregroundStyle(.secondary)) {
                    EmptyView()
                }
            }
            .navigationTitle("TelemetryDeck Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SESettingsView(_changeLog: [], _acknowledgements: [])
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
        }
        .refreshable {
            await fetchData()
        }
        .task {
            await fetchData()
        }
    }

    var defaultProfileImage: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(.accent)
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

    private func getGravatarURL(for email: String) -> URL? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailHash = Insecure.MD5.hash(data: Data(trimmedEmail.utf8)).map {
            String(format: "%02hhx", $0)
        }.joined()
        return URL(string: "https://www.gravatar.com/avatar/\(emailHash)?s=200&d=identicon")
    }
}

#Preview {
    MainView()
        .environmentObject(APIClient.preview)
}
