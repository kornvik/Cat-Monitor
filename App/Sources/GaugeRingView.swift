import SwiftUI

struct GaugeRingView: View {
    let value: Double
    let color: Color
    let label: String
    var centerText: String? = nil

    @State private var displayValue: Double
    @State private var animationsEnabled = false

    private let lineWidth: CGFloat = 2.5
    private let ringSize: CGFloat = 44

    init(value: Double, color: Color, label: String, centerText: String? = nil) {
        self.value = value
        self.color = color
        self.label = label
        self.centerText = centerText
        _displayValue = State(initialValue: value)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: displayValue)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(centerText ?? "\(Int(value * 100))%")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: ringSize, height: ringSize)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            displayValue = value
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                animationsEnabled = true
            }
        }
        .onChange(of: value) { newValue in
            if animationsEnabled {
                withAnimation(.easeInOut(duration: 0.6)) {
                    displayValue = newValue
                }
            } else {
                displayValue = newValue
            }
        }
    }
}
