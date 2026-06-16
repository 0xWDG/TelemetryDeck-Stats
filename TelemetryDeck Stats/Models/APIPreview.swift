//
//  APIPreview.swift
//  TelemetryDeck Stats
//
//  Created by Wesley de Groot on 27/01/2026.
//

import Foundation

extension APIClient {
    /// Creates a preview APIClient with mock data for SwiftUI previews
    static var preview: APIClient {
        let client = APIClient()
        client.applyPreviewData()
        return client
    }

    func applyPreviewData() {
        isPreview = true
        isAuthenticated = true
        currentUser = TDUser(
            id: "preview-user-1",
            email: "demo@example.com",
            firstName: "Demo",
            lastName: "User"
        )
        organizations = [
            TDOrganization(
                id: "preview-org-1",
                name: "My Organization",
                description: "A demo organization",
                roleOrganizationPermissions: "Administrate"
            )
        ]
        selectedOrganization = organizations.first
        apps = TDApps(
            id: "0",
            apps: [
                TDApp(
                    id: "preview-app-1",
                    name: "iOS App",
                    organizationID: "preview-org-1",
                    settings: .init(displayMode: "app"),
                    insightGroups: []
                ),
                TDApp(
                    id: "preview-app-2",
                    name: "Web App",
                    organizationID: "preview-org-1",
                    settings: .init(displayMode: "website"),
                    insightGroups: []
                )
            ],
            maxSignals: 100000,
            billingModel: "free",
            usagePercentage: 0.25,
            namespace: "nl.wesleydegroot.test"
        )
        let previewInsights = TDInsights(
            result: .init(
                rows: (1 ... 29).reversed().map {
                    .init(
                        result: .init(users: Int.random(in: 10 ... 150)),
                        timestamp: Date.now.addingTimeInterval(-Double($0) * 24 * 60 * 60)
                    )
                }
            ),
            calculationFinishedAt: Date.now.formatted(.iso8601)
        )

        insights = previewInsights
        insightsByAppID["preview-app-1"] = previewInsights
        insightsByAppID["preview-app-2"] = previewInsights
    }
}
