import SwiftUI

struct HardwareInfoView: View {
    let cpuTemp: Double?
    let gpuTemp: Double?
    var useFahrenheit: Bool = false

    private var isSameChip: Bool {
        HardwareInfo.cpuName == HardwareInfo.gpuName
            || HardwareInfo.gpuName == "Integrated"
    }

    var body: some View {
        if isSameChip {
            sameChipLayout
        } else {
            separateChipLayout
        }
    }

    private var sameChipLayout: some View {
        VStack(spacing: 6) {
            Text(HardwareInfo.cpuName)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)

            HStack {
                tempBadge(label: "CPU", temp: cpuTemp)
                Spacer()
                tempBadge(label: "GPU", temp: gpuTemp)
            }
        }
    }

    private var separateChipLayout: some View {
        VStack(spacing: 8) {
            chipRow(label: "CPU", name: HardwareInfo.cpuName, temp: cpuTemp)
            chipRow(label: "GPU", name: HardwareInfo.gpuName, temp: gpuTemp)
        }
    }

    private func formatTemp(_ celsius: Double) -> String {
        if useFahrenheit {
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.0f \u{00B0}F", f)
        }
        return String(format: "%.0f \u{00B0}C", celsius)
    }

    private var unitSuffix: String {
        useFahrenheit ? " \u{00B0}F" : " \u{00B0}C"
    }

    private func tempBadge(label: String, temp: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            if let temp {
                Text(formatTemp(temp))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(tempColor(temp))
            } else {
                Text("--\(unitSuffix)")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chipRow(label: String, name: String, temp: Double?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text(name)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            if let temp {
                Text(formatTemp(temp))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(tempColor(temp))
            } else {
                Text("--\(unitSuffix)")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        temp >= 80 ? Color(red: 1.0, green: 0.25, blue: 0.2) : .primary
    }
}
