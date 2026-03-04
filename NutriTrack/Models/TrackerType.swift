import Foundation
import SwiftUI

// MARK: - TrackerType

struct TrackerType: Identifiable, Hashable {
    let id: String
    var displayName: String
    var unit: String
    let isBuiltIn: Bool
    var minimumGoal: Double
    var mainGoal: Double
    var displayOrder: Int
    var isEnabled: Bool
    var pieColor: String
    var ringColor: String
    var barColor: String
    var iconName: String?      // nil = show displayName text; SF Symbol name or "custom.wheat"
    var labelColor: String     // hex, e.g. "#FFFFFF"

    // MARK: - Built-in defaults

    static let defaults: [TrackerType] = [
        TrackerType(
            id: "protein",
            displayName: "Protein",
            unit: "g",
            isBuiltIn: true,
            minimumGoal: 120,
            mainGoal: 160,
            displayOrder: 0,
            isEnabled: true,
            pieColor: "#E8601C",
            ringColor: "#F4A261",
            barColor: "#E76F51",
            iconName: "figure.strengthtraining.traditional",
            labelColor: "#FFFFFF"
        ),
        TrackerType(
            id: "water",
            displayName: "Water",
            unit: "fl oz",
            isBuiltIn: true,
            minimumGoal: 80,
            mainGoal: 120,
            displayOrder: 1,
            isEnabled: true,
            pieColor: "#48CAE4",
            ringColor: "#0096C7",
            barColor: "#023E8A",
            iconName: "drop",
            labelColor: "#FFFFFF"
        )
    ]

    // MARK: - Computed helpers

    var usesIcon: Bool { iconName != nil }

    var shortUnit: String {
        unit == "fl oz" ? "oz" : unit
    }

    // MARK: - Derived helpers

    /// Pie fill fraction: [0,1] mapping intake→minimumGoal
    func pieFraction(for intake: Double) -> Double {
        guard minimumGoal > 0 else { return intake > 0 ? 1.0 : 0.0 }
        return min(intake / minimumGoal, 1.0)
    }

    /// Ring fill fraction: [0,1] mapping minimumGoal→mainGoal
    func ringFraction(for intake: Double) -> Double {
        let span = mainGoal - minimumGoal
        guard span > 0 else { return intake >= mainGoal ? 1.0 : 0.0 }
        return min(max((intake - minimumGoal) / span, 0.0), 1.0)
    }

    /// Overflow bar fraction: [0,1] mapping mainGoal→2×mainGoal
    func overflowFraction(for intake: Double) -> Double {
        guard mainGoal > 0 else { return 0.0 }
        return min(max((intake - mainGoal) / mainGoal, 0.0), 1.0)
    }

    /// Percentage of mainGoal, clamped for display
    func percentOfMainGoal(for intake: Double) -> Double {
        guard mainGoal > 0 else { return 0.0 }
        return min(intake / mainGoal, 2.0)
    }
}

// MARK: - Codable (custom, for backward compatibility)

extension TrackerType: Codable {
    enum CodingKeys: String, CodingKey {
        case id, displayName, unit, isBuiltIn, minimumGoal, mainGoal
        case displayOrder, isEnabled, pieColor, ringColor, barColor
        case iconName, labelColor
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self, forKey: .id)
        displayName  = try c.decode(String.self, forKey: .displayName)
        unit         = try c.decode(String.self, forKey: .unit)
        isBuiltIn    = try c.decode(Bool.self,   forKey: .isBuiltIn)
        minimumGoal  = try c.decode(Double.self, forKey: .minimumGoal)
        mainGoal     = try c.decode(Double.self, forKey: .mainGoal)
        displayOrder = try c.decode(Int.self,    forKey: .displayOrder)
        isEnabled    = try c.decode(Bool.self,   forKey: .isEnabled)
        pieColor     = try c.decode(String.self, forKey: .pieColor)
        ringColor    = try c.decode(String.self, forKey: .ringColor)
        barColor     = try c.decode(String.self, forKey: .barColor)
        iconName     = try c.decodeIfPresent(String.self, forKey: .iconName)
        labelColor   = try c.decodeIfPresent(String.self, forKey: .labelColor) ?? "#FFFFFF"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(displayName,  forKey: .displayName)
        try c.encode(unit,         forKey: .unit)
        try c.encode(isBuiltIn,    forKey: .isBuiltIn)
        try c.encode(minimumGoal,  forKey: .minimumGoal)
        try c.encode(mainGoal,     forKey: .mainGoal)
        try c.encode(displayOrder, forKey: .displayOrder)
        try c.encode(isEnabled,    forKey: .isEnabled)
        try c.encode(pieColor,     forKey: .pieColor)
        try c.encode(ringColor,    forKey: .ringColor)
        try c.encode(barColor,     forKey: .barColor)
        try c.encodeIfPresent(iconName, forKey: .iconName)
        try c.encode(labelColor,   forKey: .labelColor)
    }
}

// MARK: - AppStorage helpers

extension TrackerType {
    static func load(from data: Data) -> [TrackerType]? {
        try? JSONDecoder().decode([TrackerType].self, from: data)
    }

    static func encode(_ trackers: [TrackerType]) -> Data? {
        try? JSONEncoder().encode(trackers)
    }
}
