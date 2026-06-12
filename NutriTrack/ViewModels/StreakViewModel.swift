import CoreData
import Foundation
import SwiftUI

// MARK: - StreakViewModel

@MainActor
final class StreakViewModel: ObservableObject {
    @Published var streakCount: Int = 0

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Refresh

    func refreshStreak(mode: StreakMode, activeTrackers: [TrackerType]) async {
        guard mode != .off else {
            streakCount = 0
            return
        }
        let dayTotals = await fetchDayTotals()
        streakCount = StreakCalculator.currentStreak(
            mode: mode,
            activeTrackers: activeTrackers,
            dayTotals: dayTotals
        )
    }

    // MARK: - Fetch

    /// Aggregates every log entry into per-day, per-tracker totals.
    private func fetchDayTotals() async -> [Date: [String: Double]] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[Date: [String: Double]], Never>) in
            let bgCtx = self.stack.newBackgroundContext()
            bgCtx.perform {
                let request = LogEntry.fetchRequest()
                var totals: [Date: [String: Double]] = [:]
                if let entries = try? bgCtx.fetch(request) {
                    for entry in entries {
                        let day = Calendar.current.startOfDay(for: entry.safeTimestamp)
                        totals[day, default: [:]][entry.safeTrackerID, default: 0] += entry.amount
                    }
                }
                continuation.resume(returning: totals)
            }
        }
    }
}
