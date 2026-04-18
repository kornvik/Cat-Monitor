import SwiftUI

enum GaugeColor {
    /// Standard gauge: green (<60%), yellow (<85%), red (>=85%)
    static func forUsage(_ value: Double) -> Color {
        switch value {
        case ..<0.60: return Color(red: 0.2, green: 0.8, blue: 0.3)
        case ..<0.85: return Color(red: 1.0, green: 0.75, blue: 0.0)
        default:      return Color(red: 1.0, green: 0.25, blue: 0.2)
        }
    }

    /// Battery gauge: red (<20%), yellow (<50%), green (>=50%)
    static func forBattery(_ value: Double) -> Color {
        switch value {
        case ..<0.20: return Color(red: 1.0, green: 0.25, blue: 0.2)
        case ..<0.50: return Color(red: 1.0, green: 0.75, blue: 0.0)
        default:      return Color(red: 0.2, green: 0.8, blue: 0.3)
        }
    }
}
