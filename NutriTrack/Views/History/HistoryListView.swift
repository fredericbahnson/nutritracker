import SwiftUI

// MARK: - HistoryListView

struct HistoryListView: View {
    let tracker: TrackerType
    let dailyTotals: [Date: Double]

    @EnvironmentObject private var themeColors: ThemeColors

    private var sortedDays: [(date: Date, total: Double)] {
        dailyTotals
            .map { (date: $0.key, total: $0.value) }
            .filter { $0.total > 0 }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sortedDays.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Start logging \(tracker.displayName.lowercased()) to see your history here.")
                )
            } else {
                List(sortedDays, id: \.date) { item in
                    HStack(spacing: 12) {
                        // Color dot
                        Circle()
                            .fill(themeColors.heatmapColor(for: item.total, tracker: tracker))
                            .frame(width: 10, height: 10)

                        // Date
                        Text(DateHelpers.shortDateString(item.date))
                            .font(Typography.label)
                            .foregroundStyle(Color(.label))

                        Spacer()

                        // Total
                        let formatted = item.total.truncatingRemainder(dividingBy: 1) == 0
                            ? String(Int(item.total))
                            : String(format: "%.1f", item.total)
                        Text("\(formatted) \(tracker.unit)")
                            .font(Typography.sfRounded(size: 15, weight: .medium))
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(DateHelpers.shortDateString(item.date)): \(formatted(item.total)) \(tracker.unit)")
                }
                .listStyle(.plain)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview {
    HistoryListView(
        tracker: TrackerType.defaults[0],
        dailyTotals: [
            Calendar.current.startOfDay(for: Date()): 145,
            Calendar.current.startOfDay(for: Date().addingTimeInterval(-86400)): 92
        ]
    )
    .environmentObject(ThemeColors())
}
