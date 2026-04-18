import Combine
import Foundation

final class StatsViewModel: ObservableObject {
    @Published var stats: SystemStatsData
    @Published var cpuTemp: Double?
    @Published var gpuTemp: Double?
    @Published var gpuUsage: Double = 0
    @Published var gpuMemUsed: UInt64 = 0
    @Published var gpuMemTotal: UInt64 = 0
    @Published var showSettings = false
    @Published var useFahrenheit: Bool
    var popoverVisible = false
    private var timer: Timer?
    private let storage = AppGroupStorage.shared
    private var tickCount = 0

    init() {
        useFahrenheit = storage.useFahrenheit
        SMCTemperature.open()
        stats = SystemStats.fetchAll(storage: storage)
        gpuUsage = GPUStats.utilization()
        refreshPopoverData()
        startTimer()
    }

    func toggleTemperatureUnit() {
        useFahrenheit.toggle()
        storage.useFahrenheit = useFahrenheit
    }

    deinit {
        timer?.invalidate()
        SMCTemperature.close()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            self.tickCount += 1
            self.stats = SystemStats.fetchAll(storage: self.storage)
            self.gpuUsage = GPUStats.utilization()

            guard self.popoverVisible else { return }

            let mem = GPUStats.memory()
            self.gpuMemUsed = mem.used
            self.gpuMemTotal = mem.total
            if self.tickCount % 3 == 0 {
                self.refreshTemps()
            }
        }
    }

    func refreshPopoverData() {
        let mem = GPUStats.memory()
        gpuMemUsed = mem.used
        gpuMemTotal = mem.total
        refreshTemps()
    }

    private func refreshTemps() {
        cpuTemp = SMCTemperature.cpuTemperature()
        gpuTemp = SMCTemperature.gpuTemperature()
    }
}
