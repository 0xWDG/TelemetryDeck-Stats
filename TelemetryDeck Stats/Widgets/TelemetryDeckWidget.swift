////
////  TelemetryDeckWidget.swift
////  Telemetrydeck Stats
////
////  Widget Extension for displaying app statistics
////
//
//import SwiftUI
//import WidgetKit
//
//// MARK: - Widget Entry
//
//struct StatisticsEntry: TimelineEntry {
//    let date: Date
//    let appName: String
//    let insightTitle: String
//    let value: String
//    let change: String?
//}
//
//// MARK: - Timeline Provider
//
//struct StatisticsProvider: TimelineProvider {
//    func placeholder(in context: Context) -> StatisticsEntry {
//        StatisticsEntry(
//            date: Date(),
//            appName: "My App",
//            insightTitle: "Active Users",
//            value: "1,234",
//            change: "+12%"
//        )
//    }
//    
//    func getSnapshot(in context: Context, completion: @escaping (StatisticsEntry) -> Void) {
//        let entry = StatisticsEntry(
//            date: Date(),
//            appName: "My App",
//            insightTitle: "Active Users",
//            value: "1,234",
//            change: "+12%"
//        )
//        completion(entry)
//    }
//    
//    func getTimeline(in context: Context, completion: @escaping (Timeline<StatisticsEntry>) -> Void) {
//        // In production, fetch real data from UserDefaults or shared container
//        // For now, use mock data
//        let currentDate = Date()
//        
//        // Check for saved widget configuration
//        if let savedData = UserDefaults(suiteName: "group.telemetrydeck.viewer")?.data(forKey: "widgetData"),
//           let widgetData = try? JSONDecoder().decode(TDWidgetData.self, from: savedData) {
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
//            // No configuration yet, show placeholder
//            let entry = placeholder(in: context)
//            let timeline = Timeline(entries: [entry], policy: .never)
//            completion(timeline)
//        }
//    }
//}
//
//// MARK: - Widget View
//
//struct StatisticsWidgetView: View {
//    let entry: StatisticsEntry
//    @Environment(\.widgetFamily) var family
//    
//    var body: some View {
//        ZStack {
//            // Background - use system background colors
//            LinearGradient(
//                gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//            
//            VStack(alignment: .leading, spacing: 8) {
//                // Header
//                HStack {
//                    Image(systemName: "chart.bar.fill")
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                    
//                    Text(entry.appName.uppercased())
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                }
//                
//                Spacer()
//                
//                // Main content
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(entry.insightTitle)
//                        .font(family == .systemSmall ? .caption : .subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    HStack(alignment: .firstTextBaseline, spacing: 4) {
//                        Text(entry.value)
//                            .font(family == .systemSmall ? .title2 : .largeTitle)
//                            .fontWeight(.bold)
//                        
//                        if let change = entry.change {
//                            Text(change)
//                                .font(.caption)
//                                .foregroundColor(change.hasPrefix("+") ? .green : .red)
//                                .padding(.horizontal, 6)
//                                .padding(.vertical, 2)
//                                .background(
//                                    Capsule()
//                                        .fill(change.hasPrefix("+") ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
//                                )
//                        }
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//}
//
//// MARK: - Widget Configuration
//
//@main
//struct TelemetryDeckWidget: Widget {
//    let kind: String = "TelemetryDeckWidget"
//    
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: StatisticsProvider()) { entry in
//            StatisticsWidgetView(entry: entry)
//        }
//        .configurationDisplayName("App Statistics")
//        .description("Display statistics from your TelemetryDeck apps")
//        .supportedFamilies([.systemSmall, .systemMedium])
//    }
//}
//
//// MARK: - Previews
//
//#if DEBUG
//struct TelemetryDeckWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            StatisticsWidgetView(entry: StatisticsEntry(
//                date: Date(),
//                appName: "My App",
//                insightTitle: "Active Users",
//                value: "1,234",
//                change: "+12%"
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            
//            StatisticsWidgetView(entry: StatisticsEntry(
//                date: Date(),
//                appName: "Web App",
//                insightTitle: "Page Views",
//                value: "45.2K",
//                change: "-3%"
//            ))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//        }
//    }
//}
//#endif
