import Foundation
import SwiftUI

// MARK: - TrackerType

struct TrackerType: Identifiable, Codable, Hashable {
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
            barColor: "#E76F51"
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
            barColor: "#023E8A"
        )
    ]

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

// MARK: - AppStorage helpers

extension TrackerType {
    static func load(from data: Data) -> [TrackerType]? {
        try? JSONDecoder().decode([TrackerType].self, from: data)
    }

    static func encode(_ trackers: [TrackerType]) -> Data? {
        try? JSONEncoder().encode(trackers)
    }
}
