import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: SystemStatsEntry

    private let catOverlap: CGFloat = 30

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Inner card for stats — inset from top for cat zone
            VStack(spacing: 6) {
                StatsGridView(stats: entry.stats)

                NetworkStatsView(
                    upload: entry.stats.uploadSpeed,
                    download: entry.stats.downloadSpeed
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.18))
            )
            .padding(.top, catOverlap)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)

            // Cat hanging over the inner card's top-right edge
            CatCharacterView(expression: entry.catExpression)
                .offset(x: -18, y: catOverlap - 26)
        }
    }
}
