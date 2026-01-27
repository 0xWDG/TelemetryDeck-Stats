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
        client.isPreview = true
        client.isAuthenticated = true
        client.currentUser = TDUser(
            id: "preview-user-1",
            email: "demo@example.com",
            firstName: "Demo",
            lastName: "User"
        )
        client.organizations = [
            TDOrganization(
                id: "preview-org-1",
                name: "My Organization",
                description: "A demo organization",
                roleOrganizationPermissions: "Administrate"
            )
        ]
        client.selectedOrganization = client.organizations.first
        client.apps = TDApps(
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
                    settings: .init(displayMode: "app"),
                    insightGroups: []
                )
            ],
            maxSignals: 100000,
            billingModel: "free",
            usagePercentage: 0.25,
            namespace: "nl.wesleydegroot.test"
        )
        client.insights = .init(
            result: .init(rows: [
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-29 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-28 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-27 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-26 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-25 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-24 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-23 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-22 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-21 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-20 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-19 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-18 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-17 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-16 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-15 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-14 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-13 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-12 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-11 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-10 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-9 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-8 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-6 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-5 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-4 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-3 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-2 * 24 * 60 * 60)),
                .init(result: .init(Users: Int.random(in: 10...150)), timestamp: Date().addingTimeInterval(-1 * 24 * 60 * 60))
            ]),
            calculationFinishedAt: "\(Date())"
        )

        return client
    }
}
