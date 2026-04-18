import SwiftUI

struct StatsGridView: View {
    let stats: SystemStatsData

    var body: some View {
        HStack(spacing: 0) {
            GaugeRingView(
                value: stats.cpuUsage,
                color: GaugeColor.forUsage(stats.cpuUsage),
                icon: "cpu",
                label: "CPU"
            )
            .frame(maxWidth: .infinity)

            GaugeRingView(
                value: stats.memoryUsage,
                color: GaugeColor.forUsage(stats.memoryUsage),
                icon: "memorychip",
                label: "MEM"
            )
            .frame(maxWidth: .infinity)

            GaugeRingView(
                value: stats.diskUsage,
                color: GaugeColor.forUsage(stats.diskUsage),
                icon: "internaldrive",
                label: "DISK"
            )
            .frame(maxWidth: .infinity)

            GaugeRingView(
                value: stats.batteryLevel,
                color: GaugeColor.forBattery(stats.batteryLevel),
                icon: stats.isCharging ? "battery.100.bolt" : "battery.50",
                label: "BAT"
            )
            .frame(maxWidth: .infinity)
        }
    }
}
