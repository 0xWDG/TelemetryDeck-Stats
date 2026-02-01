////
////  TelemetryDeckWidget.swift
////  Telemetrydeck Stats
////
////  Widget Extension for displaying app statistics
////

import SwiftUI
import WidgetKit
import SwiftExtras
import AppIntents

// MARK: - Widget Configuration

enum TimePeriod: String, Codable, AppEnum {
    case today = "Today"
    case last30Days = "Last 30 Days"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Period"
    static var caseDisplayRepresentations: [TimePeriod: DisplayRepresentation] = [
        .today: "Today",
        .last30Days: "Last 30 Days"
    ]
    
    var offset: Int {
        switch self {
        case .today: return 1
        case .last30Days: return 30
        }
    }
}

struct WidgetConfiguration: Codable {
    var timePeriod: TimePeriod
    var hiddenAppIDs: [String]
    
    init(timePeriod: TimePeriod = .last30Days, hiddenAppIDs: [String] = []) {
        self.timePeriod = timePeriod
        self.hiddenAppIDs = hiddenAppIDs
    }
}

struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description = IntentDescription("Configure your TelemetryDeck widget")
    
    @Parameter(title: "Time Period", default: .last30Days)
    var timePeriod: TimePeriod
    
    @Parameter(title: "Hidden Apps", default: [])
    var hiddenAppIDs: [String]
}

// MARK: - Widget Entry

struct StatisticsEntry: TimelineEntry, Codable {
    let date: Date
    let stats: [Statistics]
    let error: String?
    let configuration: WidgetConfiguration

    struct Statistics: Codable, Identifiable {
        let id: String
        let name: String
        let value: Int
        let displayMode: String
    }
}

// MARK: - Timeline Provider

struct StatisticsProvider: AppIntentTimelineProvider {
    func errorview(in context: Context, error: Error, configuration: WidgetConfiguration) -> StatisticsEntry {
        StatisticsEntry(
            date: Date(),
            stats: [],
            error: error.localizedDescription,
            configuration: configuration
        )
    }

    func placeholder(in context: Context) -> StatisticsEntry {
        StatisticsEntry(
            date: Date(),
            stats: [],
            error: nil,
            configuration: WidgetConfiguration()
        )
    }

    func snapshot(for configuration: ConfigurationIntent, in context: Context) async -> StatisticsEntry {
        if context.isPreview {
            return StatisticsEntry(
                date: Date(),
                stats: [
                    .init(id: "1", name: "Sample App", value: 1234, displayMode: "app"),
                    .init(id: "2", name: "Another App", value: 567, displayMode: "globe")
                ],
                error: nil,
                configuration: WidgetConfiguration(
                    timePeriod: configuration.timePeriod,
                    hiddenAppIDs: configuration.hiddenAppIDs
                )
            )
        }
        
        return loadWidgetData(configuration: configuration)
    }

    func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<StatisticsEntry> {
        let entry = loadWidgetData(configuration: configuration)
        
        // Update every 2 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadWidgetData(configuration: ConfigurationIntent) -> StatisticsEntry {
        let widgetConfig = WidgetConfiguration(
            timePeriod: configuration.timePeriod,
            hiddenAppIDs: configuration.hiddenAppIDs
        )
        
        // Load data from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.nl.wesleydegroot.TelemetryDeckStats"),
           let savedData = sharedDefaults.data(forKey: "widgetData"),
           let widgetData = try? JSONDecoder().decode(StatisticsEntry.self, from: savedData) {
            
            // Filter out hidden apps
            let filteredStats = widgetData.stats.filter { stat in
                !widgetConfig.hiddenAppIDs.contains(stat.id)
            }
            
            return StatisticsEntry(
                date: Date(),
                stats: filteredStats,
                error: nil,
                configuration: widgetConfig
            )
        }
        
        // No data available
        return StatisticsEntry(
            date: Date(),
            stats: [],
            error: nil,
            configuration: widgetConfig
        )
    }
}

// MARK: - Widget View

struct StatisticsWidgetView: View {
    let entry: StatisticsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = entry.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entry.stats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Data Available")
                        .font(.headline)
                    Text("Open the app to sync your statistics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Statistics")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(entry.configuration.timePeriod.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 4)
                    
                    let maxItems = switch family {
                    case .systemLarge: 12
                    default: 5
                    }
                    
                    ForEach(entry.stats.prefix(maxItems)) { stat in
                        LabeledContent {
                            Text("\(stat.value)")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: stat.displayMode == "app" ? "apps.iphone" : "globe")
                                    .foregroundColor(.accentColor)
                                Text(stat.name)
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption)
                    }
                    
                    if entry.stats.count > maxItems {
                        Text("+ \(entry.stats.count - maxItems) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
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
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
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
        Group {
            // With data
            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [
                    .init(id: "1", name: "DVG Valley Guide", value: 1234, displayMode: "app"),
                    .init(id: "2", name: "Website", value: 567, displayMode: "globe"),
                    .init(id: "3", name: "Mobile App", value: 890, displayMode: "app"),
                    .init(id: "4", name: "Web Portal", value: 345, displayMode: "globe"),
                    .init(id: "5", name: "Test App", value: 123, displayMode: "app")
                ],
                error: nil,
                configuration: WidgetConfiguration(timePeriod: .last30Days)
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - With Data")

            // Large widget
            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [
                    .init(id: "1", name: "DVG Valley Guide", value: 1234, displayMode: "app"),
                    .init(id: "2", name: "Website", value: 567, displayMode: "globe"),
                    .init(id: "3", name: "Mobile App", value: 890, displayMode: "app"),
                    .init(id: "4", name: "Web Portal", value: 345, displayMode: "globe"),
                    .init(id: "5", name: "Test App", value: 123, displayMode: "app"),
                    .init(id: "6", name: "Another App", value: 678, displayMode: "app")
                ],
                error: nil,
                configuration: WidgetConfiguration(timePeriod: .today)
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - With Data")
            
            // Empty state
            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [],
                error: nil,
                configuration: WidgetConfiguration()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Empty State")
            
            // Error state
            StatisticsWidgetView(entry: StatisticsEntry(
                date: Date(),
                stats: [],
                error: "Failed to load data",
                configuration: WidgetConfiguration()
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Error State")
        }
    }
}
#endif
