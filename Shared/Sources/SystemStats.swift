import Foundation
import IOKit.ps

// MARK: - Data Models

struct SystemStatsData {
    var cpuUsage: Double      // 0.0–1.0
    var memoryUsage: Double   // 0.0–1.0
    var diskUsage: Double     // 0.0–1.0
    var batteryLevel: Double  // 0.0–1.0
    var isCharging: Bool
    var uploadSpeed: Double   // bytes/sec
    var downloadSpeed: Double // bytes/sec

    static let placeholder = SystemStatsData(
        cpuUsage: 0.35,
        memoryUsage: 0.55,
        diskUsage: 0.42,
        batteryLevel: 0.80,
        isCharging: false,
        uploadSpeed: 1024 * 50,
        downloadSpeed: 1024 * 200
    )
}

// MARK: - System Stats Fetching

enum SystemStats {

    // MARK: CPU

    private static let hostPort = mach_host_self()
    private static var prevCPUTicks: (user: Int64, system: Int64, idle: Int64)?

    static func cpuUsage() -> Double {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )
        guard result == KERN_SUCCESS, let info = cpuInfo else { return 0 }

        var totalUser: Int64 = 0
        var totalSystem: Int64 = 0
        var totalIdle: Int64 = 0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += Int64(info[offset + Int(CPU_STATE_USER)])
                + Int64(info[offset + Int(CPU_STATE_NICE)])
            totalSystem += Int64(info[offset + Int(CPU_STATE_SYSTEM)])
            totalIdle += Int64(info[offset + Int(CPU_STATE_IDLE)])
        }

        let cpuInfoSize = vm_size_t(MemoryLayout<integer_t>.stride) * vm_size_t(numCPUInfo)
        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: UnsafeMutableRawPointer(info)),
            cpuInfoSize
        )

        defer { prevCPUTicks = (totalUser, totalSystem, totalIdle) }

        guard let prev = prevCPUTicks else { return 0 }

        let dUser = totalUser - prev.user
        let dSystem = totalSystem - prev.system
        let dIdle = totalIdle - prev.idle
        let dTotal = dUser + dSystem + dIdle

        guard dTotal > 0 else { return 0 }
        return min(Double(dUser + dSystem) / Double(dTotal), 1.0)
    }

    // MARK: Memory

    static func memoryUsage() -> Double {
        var size = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        var stats = vm_statistics64_data_t()
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = Double(vm_kernel_page_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let freePages = Double(stats.free_count)
        let inactivePages = Double(stats.inactive_count)
        let availableMemory = (freePages + inactivePages) * pageSize

        return max(0, min(1.0 - (availableMemory / totalMemory), 1.0))
    }

    // MARK: Disk

    static func diskUsage() -> Double {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory()
            )
            guard let totalSize = attrs[.systemSize] as? Int64,
                  let freeSize = attrs[.systemFreeSize] as? Int64,
                  totalSize > 0
            else { return 0 }
            return Double(totalSize - freeSize) / Double(totalSize)
        } catch {
            return 0
        }
    }

    // MARK: Battery

    struct BatteryInfo {
        var level: Double  // 0.0–1.0
        var isCharging: Bool
    }

    static func battery() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatteryInfo(level: 1.0, isCharging: false)
        }

        let currentCap = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
        let maxCap = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
        let level = maxCap > 0 ? Double(currentCap) / Double(maxCap) : 1.0

        return BatteryInfo(level: min(max(level, 0), 1.0), isCharging: isCharging)
    }

    // MARK: Network

    struct NetworkBytes {
        var bytesIn: UInt64
        var bytesOut: UInt64
    }

    static func networkBytes() -> NetworkBytes {
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return NetworkBytes(bytesIn: 0, bytesOut: 0)
        }
        defer { freeifaddrs(ifaddr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = cursor {
            let name = String(cString: addr.pointee.ifa_name)
            // Only count en* (WiFi/Ethernet) and pdp_ip* (cellular)
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalIn += UInt64(networkData.ifi_ibytes)
                    totalOut += UInt64(networkData.ifi_obytes)
                }
            }
            cursor = addr.pointee.ifa_next
        }

        return NetworkBytes(bytesIn: totalIn, bytesOut: totalOut)
    }

    /// Compute network speed from two snapshots
    static func networkSpeed(
        previous: NetworkBytes,
        current: NetworkBytes,
        interval: TimeInterval
    ) -> (download: Double, upload: Double) {
        guard interval > 0 else { return (0, 0) }
        let dlBytes = current.bytesIn >= previous.bytesIn
            ? Double(current.bytesIn - previous.bytesIn)
            : 0
        let ulBytes = current.bytesOut >= previous.bytesOut
            ? Double(current.bytesOut - previous.bytesOut)
            : 0
        return (dlBytes / interval, ulBytes / interval)
    }

    // MARK: Fetch All

    static func fetchAll(storage: AppGroupStorage) -> SystemStatsData {
        let cpu = cpuUsage()
        let mem = memoryUsage()
        let disk = diskUsage()
        let currentNet = networkBytes()

        // Compute network speed from previous snapshot
        let prevIn = storage.previousBytesIn
        let prevOut = storage.previousBytesOut
        let prevTime = storage.previousNetworkTimestamp
        let now = Date().timeIntervalSince1970
        let interval = now - prevTime

        let prevNet = NetworkBytes(bytesIn: prevIn, bytesOut: prevOut)
        let speed = networkSpeed(previous: prevNet, current: currentNet, interval: interval)

        // Store current snapshot for next time
        storage.previousBytesIn = currentNet.bytesIn
        storage.previousBytesOut = currentNet.bytesOut
        storage.previousNetworkTimestamp = now

        return SystemStatsData(
            cpuUsage: cpu,
            memoryUsage: mem,
            diskUsage: disk,
            batteryLevel: 1.0,
            isCharging: false,
            uploadSpeed: max(speed.upload, 0),
            downloadSpeed: max(speed.download, 0)
        )
    }
}
