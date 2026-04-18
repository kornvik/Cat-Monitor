import SwiftUI

struct GaugeRingView: View {
    let value: Double      // 0.0–1.0
    let color: Color
    let icon: String       // SF Symbol name
    let label: String

    private let lineWidth: CGFloat = 2.5
    private let ringSize: CGFloat = 32

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.25), lineWidth: lineWidth)

                // Value ring
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(width: ringSize, height: ringSize)

            // Percentage
            Text("\(Int(value * 100))%")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            // Label
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
