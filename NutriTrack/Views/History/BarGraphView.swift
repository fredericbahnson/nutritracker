import SwiftUI

// MARK: - BarGraphView

struct BarGraphView: View {
    let tracker: TrackerType
    let isWeekly: Bool

    @EnvironmentObject private var historyVM: HistoryViewModel

    @State private var currentPage: Int = 0
    @State private var animationProgress: CGFloat = 0

    private var pageCount: Int { isWeekly ? 52 : 24 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pageCount, id: \.self) { pageIndex in
                    let offset = -pageIndex
                    let dates = isWeekly
                        ? DateHelpers.datesInWeek(offsetBy: offset)
                        : DateHelpers.datesInMonth(offsetBy: offset)
                    let amounts = dates.map { date -> Double in
                        let key = Calendar.current.startOfDay(for: date)
                        return historyVM.dailyTotals[key] ?? 0
                    }
                    BarGraphPageView(
                        tracker: tracker,
                        dates: dates,
                        amounts: amounts,
                        isWeekly: isWeekly,
                        animationProgress: animationProgress
                    )
                    .tag(pageIndex)
                    .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Text(pageRangeLabel)
                .font(Typography.caption)
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
        .onAppear { triggerAnimation() }
        .onChange(of: tracker.id) { _, _ in triggerAnimation() }
        .onChange(of: currentPage) { _, _ in triggerAnimation() }
    }

    // MARK: - Helpers

    private static let weekRangeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthRangeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private var pageRangeLabel: String {
        let offset = -currentPage
        let dates = isWeekly
            ? DateHelpers.datesInWeek(offsetBy: offset)
            : DateHelpers.datesInMonth(offsetBy: offset)
        guard let first = dates.first, let last = dates.last else { return "" }
        if isWeekly {
            return "\(BarGraphView.weekRangeFmt.string(from: first)) – \(BarGraphView.weekRangeFmt.string(from: last))"
        } else {
            return BarGraphView.monthRangeFmt.string(from: first)
        }
    }

    private func triggerAnimation() {
        animationProgress = 0
        withAnimation(.easeOut(duration: 0.4)) {
            animationProgress = 1
        }
    }
}

// MARK: - BarGraphPageView

private struct BarGraphPageView: View {
    let tracker: TrackerType
    let dates: [Date]
    let amounts: [Double]
    let isWeekly: Bool
    let animationProgress: CGFloat

    private let leftPad: CGFloat = 44
    private let rightPad: CGFloat = 38
    private let topPad: CGFloat = 12
    private let bottomPad: CGFloat = 28

    private var minGoal: Double { tracker.minimumGoal }
    private var mainGoal: Double { tracker.mainGoal }

    private var yMax: Double {
        let dataMax = amounts.max() ?? 0
        let base = mainGoal > 0 ? mainGoal : 100
        return max(base * 1.25, dataMax * 1.1, base)
    }

    var body: some View {
        Canvas { ctx, size in
            drawGraph(ctx: &ctx, size: size)
        }
    }

    // MARK: - Drawing

    private func yPos(for value: Double, gh: CGFloat) -> CGFloat {
        topPad + gh * CGFloat(1.0 - value / yMax)
    }

    private func barColor(for amount: Double) -> Color {
        if minGoal > 0 {
            if amount <= minGoal { return Color(hex: tracker.pieColor) }
            if amount <= mainGoal { return Color(hex: tracker.ringColor) }
            return Color(hex: tracker.barColor)
        } else {
            if amount <= mainGoal { return Color(hex: tracker.ringColor) }
            return Color(hex: tracker.barColor)
        }
    }

    private func xLabels() -> [String] {
        let cal = Calendar.current
        if isWeekly {
            let letters = ["S", "M", "T", "W", "T", "F", "S"]
            return dates.map { date in
                let wd = cal.component(.weekday, from: date)
                return letters[(wd - 1) % 7]
            }
        } else {
            let showDays: Set<Int> = [1, 8, 15, 22, 29]
            return dates.map { date in
                let day = cal.component(.day, from: date)
                return showDays.contains(day) ? "\(day)" : ""
            }
        }
    }

    private func formatY(_ val: Double) -> String {
        let rounded = val.rounded(.towardZero)
        return val == rounded ? "\(Int(val))" : String(format: "%.0f", val)
    }

    private func drawGraph(ctx: inout GraphicsContext, size: CGSize) {
        let gw = size.width - leftPad - rightPad
        let gh = size.height - topPad - bottomPad
        let bottomY = topPad + gh
        let count = dates.count
        guard count > 0, gw > 0, gh > 0, yMax > 0 else { return }

        func yp(_ v: Double) -> CGFloat { yPos(for: v, gh: gh) }

        let gap: CGFloat = isWeekly ? 6 : 2
        let bw = max(1, (gw - gap * CGFloat(count - 1)) / CGFloat(count))
        let cr: CGFloat = isWeekly ? 4 : 2

        // Baseline
        var baseline = Path()
        baseline.move(to: CGPoint(x: leftPad, y: bottomY))
        baseline.addLine(to: CGPoint(x: leftPad + gw, y: bottomY))
        ctx.stroke(baseline, with: .color(Color(.separator)), lineWidth: 1)

        // Min goal reference line + label
        if minGoal > 0, minGoal < yMax {
            let my = yp(minGoal)
            var mLine = Path()
            mLine.move(to: CGPoint(x: leftPad, y: my))
            mLine.addLine(to: CGPoint(x: leftPad + gw, y: my))
            ctx.stroke(mLine,
                       with: .color(Color(hex: tracker.pieColor).opacity(0.5)),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            ctx.draw(
                Text("min")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: tracker.pieColor).opacity(0.8)),
                at: CGPoint(x: leftPad + gw + 3, y: my),
                anchor: .leading
            )
        }

        // Main goal reference line + label
        if mainGoal > 0, mainGoal < yMax {
            let gy = yp(mainGoal)
            var gLine = Path()
            gLine.move(to: CGPoint(x: leftPad, y: gy))
            gLine.addLine(to: CGPoint(x: leftPad + gw, y: gy))
            ctx.stroke(gLine,
                       with: .color(Color(hex: tracker.ringColor).opacity(0.7)),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            ctx.draw(
                Text("goal")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: tracker.ringColor)),
                at: CGPoint(x: leftPad + gw + 3, y: gy),
                anchor: .leading
            )
        }

        // Y-axis labels (deduplicated)
        var drawnYKeys = Set<Int>()
        for val in [0.0, minGoal, mainGoal] {
            guard val >= 0, val <= yMax else { continue }
            let key = Int(val.rounded())
            guard !drawnYKeys.contains(key) else { continue }
            drawnYKeys.insert(key)
            let label = val == 0 ? "0" : formatY(val)
            ctx.draw(
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(.secondaryLabel)),
                at: CGPoint(x: leftPad - 4, y: yp(val)),
                anchor: .trailing
            )
        }

        // Bars
        for (i, amount) in amounts.enumerated() {
            let x = leftPad + CGFloat(i) * (bw + gap)
            let animated = amount * Double(animationProgress)
            guard animated > 0 else { continue }
            let bt = yp(animated)
            let bh = bottomY - bt
            guard bh > 0 else { continue }
            let rect = CGRect(x: x, y: bt, width: bw, height: bh)
            ctx.fill(Path(roundedRect: rect, cornerRadius: cr),
                     with: .color(barColor(for: amount)))
        }

        // X-axis labels
        for (i, label) in xLabels().enumerated() {
            guard !label.isEmpty else { continue }
            let cx = leftPad + CGFloat(i) * (bw + gap) + bw / 2
            ctx.draw(
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.secondaryLabel)),
                at: CGPoint(x: cx, y: bottomY + 8),
                anchor: .top
            )
        }
    }
}

// MARK: - Preview

#Preview {
    BarGraphView(tracker: TrackerType.defaults[0], isWeekly: true)
        .environmentObject(HistoryViewModel())
        .frame(height: 320)
        .padding()
}
