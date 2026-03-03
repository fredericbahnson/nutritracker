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
}
