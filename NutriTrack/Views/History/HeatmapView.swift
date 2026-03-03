import SwiftUI

// MARK: - HeatmapDayCell

struct HeatmapDayCell: View {
    let date: Date?
    let amount: Double
    let tracker: TrackerType
    let isToday: Bool
    let isCurrentMonth: Bool

    @EnvironmentObject private var themeColors: ThemeColors

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
                .opacity(isCurrentMonth ? 1.0 : 0.3)

            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(.label).opacity(0.5), lineWidth: 1.5)
            }

            if let date {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(Typography.caption)
                    .foregroundStyle(
                        amount > 0
                            ? Color(.label)
                            : Color(.tertiaryLabel)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var cellColor: Color {
        guard date != nil else { return Color.clear }
        return themeColors.heatmapColor(for: amount, tracker: tracker)
    }

    private var accessibilityLabel: String {
        guard let date else { return "Empty" }
        return DateHelpers.shortDateString(date)
    }

    private var accessibilityValue: String {
        guard amount > 0 else { return "No data" }
        let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(format: "%.1f", amount)
        return "\(formatted) \(tracker.unit)"
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
        ForEach(0..<7, id: \.self) { i in
            HeatmapDayCell(
                date: Date(),
                amount: Double(i * 20),
                tracker: TrackerType.defaults[0],
                isToday: i == 3,
                isCurrentMonth: true
            )
        }
    }
    .padding()
    .environmentObject(ThemeColors())
}
