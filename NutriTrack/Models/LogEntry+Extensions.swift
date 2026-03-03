import CoreData
import Foundation

// MARK: - LogEntry typed accessors

extension LogEntry {
    // Typed accessor helpers that avoid force-unwraps

    var safeID: UUID {
        id ?? UUID()
    }

    var safeTrackerID: String {
        trackerID ?? ""
    }

    var safeTimestamp: Date {
        timestamp ?? Date()
    }

    // MARK: - Factory

    @discardableResult
    static func create(
        trackerID: String,
        amount: Double,
        timestamp: Date = Date(),
        note: String? = nil,
        in context: NSManagedObjectContext
    ) -> LogEntry {
        let entry = LogEntry(context: context)
        entry.id = UUID()
        entry.trackerID = trackerID
        entry.amount = amount
        entry.timestamp = timestamp
        entry.note = note
        return entry
    }
}
