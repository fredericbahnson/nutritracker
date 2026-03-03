import SwiftUI

// MARK: - WeeklyHeatmapView

struct WeeklyHeatmapView: View {
    let tracker: TrackerType
    let dailyTotals: [Date: Double]

    @EnvironmentObject private var themeColors: ThemeColors

    // Current week offset from today (0 = this week, -1 = last week, ...)
    @State private var weekOffset: Int = 0

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var weekDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday
        let today = Date()
        let startOfThisWeek = DateHelpers.startOfWeek(containing: today, calendar: cal)
        guard let weekStart = cal.date(
            byAdding: .weekOfYear,
            value: weekOffset,
            to: startOfThisWeek
        ) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Swipe gesture overlay using TabView-style pagination
            TabView(selection: $weekOffset) {
                ForEach(-52...0, id: \.self) { offset in
                    weekPage(for: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 110)

            Text(weekRangeLabel)
                .font(Typography.caption)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.top, 4)
        }
    }

    private func weekPage(for offset: Int) -> some View {
        var cal = Calendar.current
        cal.firstWeekday = 1
        let today = Date()
        let startOfThisWeek = DateHelpers.startOfWeek(containing: today, calendar: cal)
        let weekStart = cal.date(byAdding: .weekOfYear, value: offset, to: startOfThisWeek) ?? today
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }

        return VStack(spacing: 6) {
            // Day labels
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(Typography.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let dayKey = Calendar.current.startOfDay(for: day)
                    let amount = dailyTotals[dayKey] ?? 0
                    let isToday = Calendar.current.isDateInToday(day)

                    HeatmapDayCell(
                        date: day,
                        amount: amount,
                        tracker: tracker,
                        isToday: isToday,
                        isCurrentMonth: true
                    )
                    .environmentObject(themeColors)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }
}

// MARK: - Preview

#Preview {
    WeeklyHeatmapView(
        tracker: TrackerType.defaults[0],
        dailyTotals: [:]
    )
    .environmentObject(ThemeColors())
    .padding()
}
