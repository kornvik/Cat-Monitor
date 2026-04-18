import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        if viewModel.showSettings {
            SettingsPanel(viewModel: viewModel)
        } else {
            statsContent
        }
    }

    private var statsContent: some View {
        VStack(spacing: 14) {
            // Gauges: CPU, GPU, Memory, Disk
            HStack(spacing: 14) {
                GaugeRingView(
                    value: viewModel.stats.cpuUsage,
                    color: GaugeColor.forUsage(viewModel.stats.cpuUsage),
                    label: "CPU"
                )
                GaugeRingView(
                    value: viewModel.stats.memoryUsage,
                    color: GaugeColor.forUsage(viewModel.stats.memoryUsage),
                    label: "Memory"
                )
                GaugeRingView(
                    value: viewModel.gpuUsage,
                    color: GaugeColor.forUsage(viewModel.gpuUsage),
                    label: "GPU"
                )
                GaugeRingView(
                    value: viewModel.stats.diskUsage,
                    color: GaugeColor.forUsage(viewModel.stats.diskUsage),
                    label: "Disk"
                )
            }

            Divider()

            // Temperature
            HardwareInfoView(
                cpuTemp: viewModel.cpuTemp,
                gpuTemp: viewModel.gpuTemp,
                useFahrenheit: viewModel.useFahrenheit
            )

            Divider()

            // GPU Memory
            HStack {
                Text("GPU Memory")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                let ratio = viewModel.gpuMemTotal > 0
                    ? Int(Double(viewModel.gpuMemUsed) / Double(viewModel.gpuMemTotal) * 100)
                    : 0
                Text("\(HardwareInfo.formatBytes(viewModel.gpuMemUsed)) / \(HardwareInfo.formatBytes(viewModel.gpuMemTotal))  (\(ratio)%)")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Divider()

            // Network
            NetworkStatsView(
                upload: viewModel.stats.uploadSpeed,
                download: viewModel.stats.downloadSpeed
            )
        }
        .padding(16)
        .padding(.top, 12)
        .overlay(alignment: .topTrailing) {
            Button(action: { viewModel.showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}
