////
////  TelemetryDeckWidget.swift
////  Telemetrydeck Stats
////
////  Widget Extension for displaying app statistics
////

import SwiftUI
import WidgetKit
import SwiftExtras

// MARK: - Widget Entry

struct StatisticsEntry: TimelineEntry, Codable {
    let date: Date
    let stats: [Statistics]
    let error: String?

    struct Statistics: Codable {
        let name: String
        let value: Int
    }
}

// MARK: - Timeline Provider

struct StatisticsProvider: TimelineProvider {
    func errorview(in context: Context, error: Error) -> StatisticsEntry {
        StatisticsEntry(
            date: Date(),
            stats: [],
            error: error.localizedDescription
        )
    }

    func placeholder(in context: Context) -> StatisticsEntry {
        StatisticsEntry(
            date: Date(),
            stats: [],
            error: nil
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (StatisticsEntry) -> Void
    ) {
        let entry = StatisticsEntry(
            date: Date(),
            stats: [],
            error: nil
        )
        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<StatisticsEntry>
        ) -> Void) {
        // In production, fetch real data from UserDefaults or shared container
        // For now, use mock data
        let currentDate = Date()

        Task {
            do {
                try await APIClient().fetchInsights(offset: 1)
            } catch {
                let entry = errorview(in: context, error: error)
                let timeline = Timeline(entries: [entry], policy: .never)
                completion(timeline)
            }
        }

        // Check for saved widget configuration
        //        if let savedData = UserDefaults(
        //            suiteName: "group.telemetrydeck.viewer"
        //        )?.data(forKey: "widgetData"),
        //           let widgetData = try? JSONDecoder().decode(StatisticsEntry.self, from: savedData) {
        //            let entry = StatisticsEntry(
        //                date: currentDate,
        //                appName: widgetData.appName,
        //                insightTitle: widgetData.insightTitle,
        //                value: widgetData.value,
        //                change: widgetData.change
        //            )
        //
        //            // Update every 2 hours
        //            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
        //            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        //            completion(timeline)
        //        } else {
        // No configuration yet, show placeholder
        let entry = placeholder(in: context)
        let timeline = Timeline(
            entries: [entry],
            policy: .never
        )
        completion(timeline)
        //        }
    }
}

// MARK: - Widget View

struct StatisticsWidgetView: View {
    let entry: StatisticsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = entry.error {
                Text(error.localizedDescription)
            } else {
                let maxItems = switch family {
                case .systemLarge: 12
                default: 5
                }

                ForEach(0 ..< maxItems) { _ in
                    LabeledContent {
                        Text("Value")
                    } label: {
                        HStack {
                            Image(systemName: "app" == "app" ? "apps.iphone": "globe")
                            Text("DVG Valley Guide")
                        }
                    }
                }
            }
        }
        .minimumScaleFactor(0.7)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Widget Configuration

struct TelemetryDeckWidget: Widget {
    let kind: String = "TelemetryDeckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: StatisticsProvider()
        ) { entry in
            StatisticsWidgetView(entry: entry)
        }
        .configurationDisplayName("App Statistics")
        .description("Display statistics from your TelemetryDeck apps")
        .supportedFamilies([
            .systemMedium,
            .systemLarge
        ])
    }
}

@main
struct TelemetryDeckWidgetBundle: WidgetBundle {
    var body: some Widget {
        TelemetryDeckWidget()
    }
}


// MARK: - Previews

#if DEBUG
struct TelemetryDeckWidget_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryDeckWidgetPreview()
    }
}

struct TelemetryDeckWidgetPreview: View {
    @State var errorMessage: String?

    var body: some View {
        Group {
            let _ = print("Error?", errorMessage)
            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [],
                error: errorMessage
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [],
                error: errorMessage
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
        .id(UUID())
        .task {
            do {
                try await APIClient().fetchInsights(offset: 1)
            } catch {
                print("Error", error)
                errorMessage = error.localizedDescription
            }

        }
    }
}
// WidgetCenter.shared.reloadAllTimelines()
#endif
