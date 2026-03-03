import Foundation

// MARK: - WaterUnit

enum WaterUnit: String, Codable, CaseIterable {
    case flOz = "floz"
    case ml = "ml"

    var displayName: String {
        switch self {
        case .flOz: return "fl oz"
        case .ml: return "ml"
        }
    }

    var canonicalSymbol: String {
        switch self {
        case .flOz: return "fl oz"
        case .ml: return "ml"
        }
    }
}

// MARK: - UnitConversion

enum UnitConversion {
    private static let flOzToMlFactor: Double = 29.5735

    static func flOzToMl(_ value: Double) -> Double {
        value * flOzToMlFactor
    }

    static func mlToFlOz(_ value: Double) -> Double {
        value / flOzToMlFactor
    }

    static func convert(
        _ amount: Double,
        from source: WaterUnit,
        to destination: WaterUnit
    ) -> Double {
        guard source != destination else { return amount }
        switch (source, destination) {
        case (.flOz, .ml): return flOzToMl(amount)
        case (.ml, .flOz): return mlToFlOz(amount)
        default: return amount
        }
    }

    /// Format a water amount for display in the given unit (1 decimal place)
    static func formatWater(_ canonicalFlOz: Double, in unit: WaterUnit) -> String {
        let displayAmount = convert(canonicalFlOz, from: .flOz, to: unit)
        return String(format: "%.1f", displayAmount)
    }
}
