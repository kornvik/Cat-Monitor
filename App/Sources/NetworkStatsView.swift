import SwiftUI

struct NetworkStatsView: View {
    let upload: Double
    let download: Double

    var body: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.blue)
            Text(formatSpeed(download))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Text(formatSpeed(upload))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
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
