import Foundation

// MARK: - DateHelpers

enum DateHelpers {
    static func startOfDay(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func dayBoundary(
        for date: Date,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    static func startOfWeek(
        containing date: Date,
        calendar: Calendar = .current
    ) -> Date {
        var cal = calendar
        cal.firstWeekday = 1 // Sunday
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    static func startOfMonth(
        containing date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func daysInMonth(
        containing date: Date,
        calendar: Calendar = .current
    ) -> Int {
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }

    static func weeksInMonth(
        containing date: Date,
        calendar: Calendar = .current
    ) -> [[Date?]] {
        var cal = calendar
        cal.firstWeekday = 1 // Sunday
        let monthStart = startOfMonth(containing: date, calendar: cal)
        let daysCount = daysInMonth(containing: date, calendar: cal)

        // Weekday of month start (Mon=0 ... Sun=6)
        let startWeekday = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7

        var allDays: [Date?] = Array(repeating: nil, count: startWeekday)
        for day in 0..<daysCount {
            if let d = cal.date(byAdding: .day, value: day, to: monthStart) {
                allDays.append(d)
            }
        }
        // Pad to complete weeks
        while allDays.count % 7 != 0 {
            allDays.append(nil)
        }

        return stride(from: 0, to: allDays.count, by: 7).map {
            Array(allDays[$0..<min($0 + 7, allDays.count)])
        }
    }

    static func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Returns the 7 dates (Mon→Sun) for the week `weekOffset` weeks from today.
    /// weekOffset 0 = current week, -1 = last week, etc.
    static func datesInWeek(offsetBy weekOffset: Int) -> [Date] {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard
            let thisMonday = cal.date(byAdding: .day, value: -daysSinceMonday,
                                      to: cal.startOfDay(for: today)),
            let targetMonday = cal.date(byAdding: .weekOfYear, value: weekOffset,
                                        to: thisMonday)
        else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: targetMonday) }
    }

    /// Returns every date in the calendar month `monthOffset` months from today.
    /// monthOffset 0 = this month, -1 = last month, etc.
    static func datesInMonth(offsetBy monthOffset: Int) -> [Date] {
        let cal = Calendar.current
        guard let target = cal.date(byAdding: .month, value: monthOffset, to: Date()) else { return [] }
        let comps = cal.dateComponents([.year, .month], from: target)
        guard let first = cal.date(from: comps) else { return [] }
        let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        return (0..<days).compactMap { cal.date(byAdding: .day, value: $0, to: first) }
    }
}
