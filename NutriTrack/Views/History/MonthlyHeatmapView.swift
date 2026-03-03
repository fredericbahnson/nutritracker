import SwiftUI

// MARK: - MonthlyHeatmapView

struct MonthlyHeatmapView: View {
    let tracker: TrackerType
    let dailyTotals: [Date: Double]

    @EnvironmentObject private var themeColors: ThemeColors

    @State private var monthOffset: Int = 0
    @State private var availableWidth: CGFloat = 350

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var calendarHeight: CGFloat {
        // Square cell width: subtract 32pt (16pt padding × 2) and 24pt (6 column gaps × 4pt)
        let cellSize = (availableWidth - 32 - 24) / 7
        // 6 rows of cells + 7 VStack gaps (8pt each) + header (~20pt) + day labels (~15pt) + buffer
        return cellSize * 6 + 112
    }

    private func monthDate(for offset: Int) -> Date {
        let today = Date()
        let startOfMonth = DateHelpers.startOfMonth(containing: today)
        return Calendar.current.date(byAdding: .month, value: offset, to: startOfMonth) ?? today
    }

    var body: some View {
        VStack(spacing: 0) {
            // Zero-height width probe — measures available width without affecting layout
            GeometryReader { geo in
                Color.clear
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in availableWidth = w }
            }
            .frame(height: 0)

            TabView(selection: $monthOffset) {
                ForEach(-24...0, id: \.self) { offset in
                    monthPage(for: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: calendarHeight)
        }
    }

    private func monthPage(for offset: Int) -> some View {
        let monthDate = monthDate(for: offset)
        let weeks = DateHelpers.weeksInMonth(containing: monthDate)
        let headerText = monthHeader(for: monthDate)

        return VStack(spacing: 8) {
            Text(headerText)
                .font(Typography.sfPro(size: 16, weight: .semibold))
                .foregroundStyle(Color(.label))

            // Day of week labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(dayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(Typography.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity)
                }
            }

            // Weeks
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, optionalDate in
                        if let date = optionalDate {
                            let dayKey = Calendar.current.startOfDay(for: date)
                            let amount = dailyTotals[dayKey] ?? 0
                            let isToday = Calendar.current.isDateInToday(date)
                            let isCurrentMonth = Calendar.current.isDate(date, equalTo: monthDate, toGranularity: .month)

                            HeatmapDayCell(
                                date: date,
                                amount: amount,
                                tracker: tracker,
                                isToday: isToday,
                                isCurrentMonth: isCurrentMonth
                            )
                            .environmentObject(themeColors)
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func monthHeader(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    MonthlyHeatmapView(
        tracker: TrackerType.defaults[0],
        dailyTotals: [:]
    )
    .environmentObject(ThemeColors())
    .padding()
}
