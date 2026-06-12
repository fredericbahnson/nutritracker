import Foundation

// MARK: - StreakCalculator

/// Pure streak math — no Core Data, fully unit-testable.
enum StreakCalculator {
    /// Number of consecutive qualifying days ending today.
    ///
    /// Today counts as soon as it qualifies, but an unqualified today does not
    /// break the streak — the day isn't over yet, so counting continues from
    /// yesterday.
    ///
    /// - Parameter dayTotals: start-of-day date → (trackerID → total logged that day)
    static func currentStreak(
        mode: StreakMode,
        activeTrackers: [TrackerType],
        dayTotals: [Date: [String: Double]],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard mode != .off, !activeTrackers.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: today)

        if dayQualifies(totals: dayTotals[day], mode: mode, activeTrackers: activeTrackers) {
            streak += 1
        }

        while let previous = calendar.date(byAdding: .day, value: -1, to: day) {
            day = previous
            guard dayQualifies(totals: dayTotals[day], mode: mode, activeTrackers: activeTrackers) else {
                break
            }
            streak += 1
        }
        return streak
    }

    /// Whether a single day counts toward the streak under the given mode.
    static func dayQualifies(
        totals: [String: Double]?,
        mode: StreakMode,
        activeTrackers: [TrackerType]
    ) -> Bool {
        let totals = totals ?? [:]
        // A day with no entries never qualifies, even when every goal is 0.
        guard totals.values.contains(where: { $0 > 0 }) else { return false }

        switch mode {
        case .off:
            return false
        case .daysTracked:
            return true
        case .minimumGoals:
            return activeTrackers.allSatisfy { (totals[$0.id] ?? 0) >= $0.minimumGoal }
        case .mainGoals:
            return activeTrackers.allSatisfy { (totals[$0.id] ?? 0) >= $0.mainGoal }
        }
    }
}
