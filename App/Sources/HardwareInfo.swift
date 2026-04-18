import Foundation
import IOKit
import Metal

// MARK: - Hardware Names

enum HardwareInfo {
    static let cpuName: String = {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "Unknown" }
        var name = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &name, &size, nil, 0)
        return String(cString: name)
    }()

    static let gpuName: String = {
        let name = MTLCreateSystemDefaultDevice()?.name ?? "Unknown"
        return name == cpuName ? "Integrated" : name
    }()

    static func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb < 1024 {
            return String(format: "%.0f MB", mb)
        }
        return String(format: "%.1f GB", mb / 1024)
    }
}

// MARK: - GPU Stats (IORegistry)

struct GPUMemoryInfo {
    var used: UInt64
    var total: UInt64
}

enum GPUStats {
    private static let metalDevice = MTLCreateSystemDefaultDevice()
    private static var cachedEntry: io_registry_entry_t = 0

    static func utilization() -> Double {
        guard let props = performanceStatistics() else { return 0 }
        let util = props["Device Utilization %"] as? Int ?? 0
        return Double(util) / 100.0
    }

    static func memory() -> GPUMemoryInfo {
        let total = metalDevice?.recommendedMaxWorkingSetSize ?? 0
        guard let props = performanceStatistics() else {
            return GPUMemoryInfo(used: 0, total: total)
        }
        let used = props["In use system memory"] as? Int ?? 0
        return GPUMemoryInfo(used: UInt64(used), total: total)
    }

    private static func performanceStatistics() -> [String: Any]? {
        // Reuse cached IORegistry entry
        if cachedEntry != 0 {
            return IORegistryEntryCreateCFProperty(
                cachedEntry, "PerformanceStatistics" as CFString,
                kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? [String: Any]
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOAccelerator"),
            &iterator
        ) == kIOReturnSuccess else { return nil }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return nil }
        cachedEntry = entry // cache for future reads (don't release)

        return IORegistryEntryCreateCFProperty(
            entry, "PerformanceStatistics" as CFString,
            kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? [String: Any]
    }
}

// MARK: - SMC Temperature Reading

enum SMCTemperature {
    private static var connection: io_connect_t = 0
    private static var isOpen = false
    private static var cpuTempKeys: [String]?
    private static var gpuTempKeys: [String]?

    static func open() {
        guard !isOpen else { return }
        for name in ["AppleSMCKeysEndpoint", "AppleSMC"] {
            let service = IOServiceGetMatchingService(
                kIOMainPortDefault,
                IOServiceMatching(name)
            )
            guard service != 0 else { continue }
            defer { IOObjectRelease(service) }
            if IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess {
                isOpen = true
                return
            }
        }
    }

    static func close() {
        guard isOpen else { return }
        IOServiceClose(connection)
        connection = 0
        isOpen = false
    }

    /// Average of all valid CPU core temperatures (filters noise < 15°C)
    static func cpuTemperature() -> Double? {
        let keys = cpuTempKeys ?? discoverKeys([
            "Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H",
            "Tp0L", "Tp0P", "Tp0X", "Tp0b", "Tp0j", "Tp0z",
            "Tp02", "Tp06", "Tp0A", "Tp0E", "Tp0I", "Tp0M",
            "Tc0a", "Tc0b", "Tc0c", "Tc0d", "Tc0x", "Tc0z",
            "Ts0P", "Ts0S",
            "TC0P", "TC0D", "TC0F", "TC0H", "TC0E",
        ], cache: &cpuTempKeys)

        let temps = keys.compactMap { readTemperature($0) }.filter { $0 > 15 && $0 < 120 }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }

    /// Average of all valid GPU temperatures
    static func gpuTemperature() -> Double? {
        let keys = gpuTempKeys ?? discoverKeys([
            "Tg0j", "Tg0f", "Tg05", "Tg0D", "Tg0L", "Tg0P",
            "Tg0T", "Tg0H", "Tg09", "Tg01",
            "TG0P", "TG0D", "TG0H", "TG0T",
        ], cache: &gpuTempKeys)

        let temps = keys.compactMap { readTemperature($0) }.filter { $0 > 15 && $0 < 120 }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }

    // MARK: - Private

    private static func discoverKeys(
        _ candidates: [String],
        cache: inout [String]?
    ) -> [String] {
        var working: [String] = []
        for key in candidates {
            if let temp = readTemperature(key), temp > 0, temp < 150 {
                working.append(key)
            }
        }
        cache = working
        return working
    }

    private static func readTemperature(_ key: String) -> Double? {
        guard isOpen else { return nil }

        var input = SMCKeyData()
        input.key = fourCC(key)
        input.data8 = 9

        guard let info = callSMC(input) else { return nil }

        var readInput = SMCKeyData()
        readInput.key = fourCC(key)
        readInput.keyInfo = info.keyInfo
        readInput.data8 = 5

        guard let result = callSMC(readInput) else { return nil }
        return parseTemp(result.bytes, type: info.keyInfo.dataType)
    }

    private static func callSMC(_ input: SMCKeyData) -> SMCKeyData? {
        var inputCopy = input
        var output = SMCKeyData()
        var outputSize = MemoryLayout<SMCKeyData>.stride

        let result = IOConnectCallStructMethod(
            connection, 2,
            &inputCopy, MemoryLayout<SMCKeyData>.stride,
            &output, &outputSize
        )
        return result == kIOReturnSuccess ? output : nil
    }

    private static func parseTemp(_ bytes: SMCBytes, type: UInt32) -> Double? {
        if type == fourCC("flt ") {
            var value: Float32 = 0
            withUnsafeMutableBytes(of: &value) { buf in
                buf[0] = bytes.0; buf[1] = bytes.1
                buf[2] = bytes.2; buf[3] = bytes.3
            }
            return Double(value)
        }
        if type == fourCC("sp78") {
            let raw = (Int16(bytes.0) << 8) | Int16(bytes.1)
            return Double(raw) / 256.0
        }
        if type == fourCC("fpe2") {
            let raw = (UInt16(bytes.0) << 8) | UInt16(bytes.1)
            return Double(raw) / 4.0
        }
        return nil
    }

    private static func fourCC(_ s: String) -> UInt32 {
        let utf8 = Array(s.utf8)
        guard utf8.count >= 4 else { return 0 }
        return UInt32(utf8[0]) << 24
            | UInt32(utf8[1]) << 16
            | UInt32(utf8[2]) << 8
            | UInt32(utf8[3])
    }
}

// MARK: - SMC Structs (80 bytes, matches kernel layout)

private typealias SMCBytes = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

private struct SMCKeyData {
    var key: UInt32 = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfo()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
}

private struct SMCVersion {
    var major: CChar = 0; var minor: CChar = 0
    var build: CChar = 0; var reserved: CChar = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0; var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0; var gpuPLimit: UInt32 = 0; var memPLimit: UInt32 = 0
}

private struct SMCKeyInfo {
    var dataSize: UInt32 = 0; var dataType: UInt32 = 0; var dataAttributes: UInt8 = 0
}
