import WidgetKit

struct SystemStatsEntry: TimelineEntry {
    let date: Date
    let stats: SystemStatsData
    let catExpression: CatExpression
}
