import CoreData
import Foundation
import SwiftUI

// MARK: - TodayViewModel

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var dailyTotals: [String: Double] = [:]
    @Published var todayEntries: [String: [LogEntry]] = [:]
    @Published var lastError: Error?

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Computed

    func dailyTotal(for trackerID: String) -> Double {
        dailyTotals[trackerID] ?? 0
    }

    func entries(for trackerID: String) -> [LogEntry] {
        todayEntries[trackerID] ?? []
    }

    // MARK: - Fetch

    func fetchTodayEntries() {
        let (start, end) = DateHelpers.dayBoundary(for: Date())
        let request = LogEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            start as NSDate,
            end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let entries = try stack.viewContext.fetch(request)
            var totals: [String: Double] = [:]
            var grouped: [String: [LogEntry]] = [:]
            for entry in entries {
                let tid = entry.safeTrackerID
                totals[tid, default: 0] += entry.amount
                grouped[tid, default: []].append(entry)
            }
            dailyTotals = totals
            todayEntries = grouped
        } catch {
            lastError = error
        }
    }

    // MARK: - Write operations

    func addEntry(trackerID: String, amount: Double) {
        guard amount > 0 else { return }
        let ctx = stack.viewContext
        LogEntry.create(trackerID: trackerID, amount: amount, in: ctx)
        if let error = stack.saveViewContext() { lastError = error }
        fetchTodayEntries()
    }

    func deleteEntry(_ entry: LogEntry) {
        let ctx = stack.viewContext
        ctx.delete(entry)
        if let error = stack.saveViewContext() { lastError = error }
        fetchTodayEntries()
    }

    func updateEntry(_ entry: LogEntry, amount: Double) {
        guard amount > 0 else { return }
        entry.amount = amount
        if let error = stack.saveViewContext() { lastError = error }
        fetchTodayEntries()
    }
}
