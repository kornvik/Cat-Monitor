import Foundation

final class AppGroupStorage {
    private let defaults: UserDefaults

    static let shared = AppGroupStorage()

    init() {
        // Both the intent and timeline provider run in the widget extension process,
        // so .standard UserDefaults is shared between them — no App Group needed.
        self.defaults = .standard
    }

    // MARK: - Cat Expression

    private static let catExpressionKey = "catExpressionIndex"

    var catExpressionIndex: Int {
        get { defaults.integer(forKey: Self.catExpressionKey) }
        set { defaults.set(newValue, forKey: Self.catExpressionKey) }
    }

    // MARK: - Network Tracking

    private static let prevBytesInKey = "prevBytesIn"
    private static let prevBytesOutKey = "prevBytesOut"
    private static let prevNetworkTimeKey = "prevNetworkTimestamp"

    var previousBytesIn: UInt64 {
        get { UInt64(defaults.integer(forKey: Self.prevBytesInKey)) }
        set { defaults.set(Int(newValue), forKey: Self.prevBytesInKey) }
    }

    var previousBytesOut: UInt64 {
        get { UInt64(defaults.integer(forKey: Self.prevBytesOutKey)) }
        set { defaults.set(Int(newValue), forKey: Self.prevBytesOutKey) }
    }

    var previousNetworkTimestamp: Double {
        get { defaults.double(forKey: Self.prevNetworkTimeKey) }
        set { defaults.set(newValue, forKey: Self.prevNetworkTimeKey) }
    }

    // MARK: - Temperature Unit

    private static let useFahrenheitKey = "useFahrenheit"

    var useFahrenheit: Bool {
        get { defaults.bool(forKey: Self.useFahrenheitKey) }
        set { defaults.set(newValue, forKey: Self.useFahrenheitKey) }
    }
}
