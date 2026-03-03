import CoreData
import Foundation
import SwiftUI

// MARK: - HistoryViewModel

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var selectedTrackerID: String = "protein"
    @Published var dailyTotals: [Date: Double] = [:]
    @Published var isLoading: Bool = false

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Fetch

    func fetchDailyTotals(from startDate: Date, to endDate: Date) async {
        isLoading = true
        let trackerID = selectedTrackerID

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<[Date: Double], Never>) in
            let bgCtx = self.stack.newBackgroundContext()
            bgCtx.perform {
                let request = LogEntry.fetchRequest()
                request.predicate = NSPredicate(
                    format: "trackerID == %@ AND timestamp >= %@ AND timestamp < %@",
                    trackerID,
                    startDate as NSDate,
                    endDate as NSDate
                )
                request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

                var totals: [Date: Double] = [:]
                if let entries = try? bgCtx.fetch(request) {
                    for entry in entries {
                        let day = Calendar.current.startOfDay(for: entry.safeTimestamp)
                        totals[day, default: 0] += entry.amount
                    }
                }
                continuation.resume(returning: totals)
            }
        }

        dailyTotals = result
        isLoading = false
    }

    // MARK: - Heatmap color

    func heatmapColor(
        for amount: Double,
        tracker: TrackerType,
        themeColors: ThemeColors
    ) -> Color {
        themeColors.heatmapColor(for: amount, tracker: tracker)
    }

    // MARK: - List data

    func listData(for dates: [Date]) -> [(date: Date, total: Double)] {
        dates
            .compactMap { date -> (Date, Double)? in
                let day = Calendar.current.startOfDay(for: date)
                let total = dailyTotals[day] ?? 0
                return total > 0 ? (day, total) : nil
            }
            .sorted { $0.0 > $1.0 }
    }
}
