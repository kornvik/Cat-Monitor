import SwiftUI
import WidgetKit

struct SystemStatsWidget: Widget {
    let kind = "SystemStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { EmptyView() }
        }
        .configurationDisplayName("Cat Monitor")
        .description("CPU, Memory, Disk, Battery & Network with a cat companion.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Timeline Provider

struct StatsTimelineProvider: TimelineProvider {
    typealias Entry = SystemStatsEntry

    func placeholder(in context: Context) -> SystemStatsEntry {
        SystemStatsEntry(date: .now, stats: .placeholder, catExpression: .frame0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemStatsEntry) -> Void) {
        let storage = AppGroupStorage.shared
        let stats = SystemStats.fetchAll(storage: storage)
        let expression = CatExpression.fromIndex(storage.catExpressionIndex)
        completion(SystemStatsEntry(date: .now, stats: stats, catExpression: expression))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemStatsEntry>) -> Void) {
        let storage = AppGroupStorage.shared
        let stats = SystemStats.fetchAll(storage: storage)
        let startIndex = storage.catExpressionIndex

        // 60 entries at 1 FPS, cycling 3 cat frames
        let expressionCount = CatExpression.allCases.count
        var entries: [SystemStatsEntry] = []
        for i in 0..<60 {
            let date = Calendar.current.date(byAdding: .second, value: i, to: .now) ?? .now
            let expression = CatExpression.fromIndex((startIndex + i) % expressionCount)
            entries.append(SystemStatsEntry(date: date, stats: stats, catExpression: expression))
        }

        storage.catExpressionIndex = (startIndex + 60) % expressionCount
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
