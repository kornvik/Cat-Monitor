import SwiftUI

struct NetworkStatsView: View {
    let upload: Double    // bytes/sec
    let download: Double  // bytes/sec

    var body: some View {
        HStack(spacing: 16) {
            speedLabel(
                icon: "arrow.down.circle.fill",
                value: download,
                color: .blue
            )
            speedLabel(
                icon: "arrow.up.circle.fill",
                value: upload,
                color: .orange
            )
        }
    }

    private func speedLabel(icon: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)

            Text(formatSpeed(value))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024
        if kb < 1024 {
            return String(format: "%.0f KB/s", kb)
        }
        let mb = kb / 1024
        return String(format: "%.1f MB/s", mb)
    }
}
