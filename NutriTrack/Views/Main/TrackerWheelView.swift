import SwiftUI

// MARK: - TrackerWheelView

struct TrackerWheelView: View {
    let tracker: TrackerType
    let dailyTotal: Double
    let size: CGFloat
    var onTap: (() -> Void)? = nil

    @EnvironmentObject private var themeColors: ThemeColors

    // Animation trigger
    @State private var animatedTotal: Double = 0

    private var ringOuter: CGFloat  { size * 0.475 }           // total radius preserved
    private var ringInner: CGFloat  { size * 0.375 }           // ring thickness = 0.1 × size
    private var pieRadius: CGFloat  { ringInner - 2 }          // 2-pt gap between pie and ring
    private var barWidth: CGFloat   { size * 0.1 }             // matches ring thickness
    private var barHeight: CGFloat { size }
    private var barX: CGFloat { ringOuter + 8 }
    private var graphicWidth: CGFloat { 2 * ringOuter + 8 + barWidth }

    // Fractions (animated)
    private var pieFraction: Double {
        tracker.pieFraction(for: animatedTotal)
    }
    private var ringFraction: Double {
        tracker.ringFraction(for: animatedTotal)
    }
    private var overflowFraction: Double {
        tracker.overflowFraction(for: animatedTotal)
    }

    private var percentDisplay: String {
        let pct = tracker.mainGoal > 0
            ? min(animatedTotal / tracker.mainGoal * 100, 200)
            : 0
        return String(format: "%.0f%%", pct)
    }

    private var amountDisplay: String {
        if animatedTotal.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(animatedTotal))
        }
        return String(format: "%.1f", animatedTotal)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Canvas { ctx, canvasSize in
                let center = CGPoint(x: ringOuter, y: canvasSize.height / 2)

                // --- Track backgrounds ---
                drawTrack(ctx: ctx, center: center, inner: 0, outer: pieRadius,
                          color: Color(.systemGray5))
                drawTrack(ctx: ctx, center: center, inner: ringInner, outer: ringOuter,
                          color: Color(.systemGray5))

                // --- Pie fill ---
                if pieFraction > 0 {
                    drawArc(
                        ctx: ctx, center: center,
                        inner: 0, outer: pieRadius,
                        fraction: pieFraction,
                        color: themeColors.pieColor(for: tracker)
                    )
                }

                // --- Ring fill ---
                if ringFraction > 0 {
                    drawArc(
                        ctx: ctx, center: center,
                        inner: ringInner, outer: ringOuter,
                        fraction: ringFraction,
                        color: themeColors.ringColor(for: tracker)
                    )
                }

                // --- Overflow bar ---
                let barRect = CGRect(
                    x: center.x + barX,
                    y: center.y - barHeight / 2,
                    width: barWidth,
                    height: barHeight
                )
                // Background track
                let trackPath = RoundedRectangle(cornerRadius: barWidth / 2)
                    .path(in: barRect)
                ctx.fill(trackPath, with: .color(Color(.systemGray5)))

                // Fill (bottom-to-top)
                if overflowFraction > 0 {
                    let fillHeight = barHeight * overflowFraction
                    let fillRect = CGRect(
                        x: barRect.minX,
                        y: barRect.maxY - fillHeight,
                        width: barWidth,
                        height: fillHeight
                    )
                    let fillPath = RoundedRectangle(cornerRadius: barWidth / 2)
                        .path(in: fillRect)
                    ctx.fill(fillPath, with: .color(themeColors.barColor(for: tracker)))
                }
            }
            .frame(width: graphicWidth, height: size)

            // Center label — constrained to ring diameter, centered on ring
            VStack(spacing: 2) {
                Text(amountDisplay)
                    .font(size > 80 ? Typography.largeNumber : Typography.mediumNumber)
                    .foregroundStyle(Color(.label))
                    .contentTransition(.numericText())

                Text("\(tracker.unit) · \(percentDisplay)")
                    .font(Typography.caption)
                    .foregroundStyle(Color(.secondaryLabel))

                Text(tracker.displayName)
                    .font(Typography.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .frame(width: 2 * ringOuter, height: size)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .onChange(of: dailyTotal) { _, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                animatedTotal = newValue
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedTotal = dailyTotal
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(tracker.displayName))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityHint(onTap != nil ? Text("Tap to log \(tracker.displayName)") : Text(""))
    }

    // MARK: - Accessibility

    private var accessibilityValue: String {
        let pct = tracker.mainGoal > 0
            ? Int(min(dailyTotal / tracker.mainGoal * 100, 200))
            : 0
        return "\(amountDisplay) \(tracker.unit), \(pct) percent of main goal"
    }

    // MARK: - Drawing helpers

    private func drawTrack(
        ctx: GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        color: Color
    ) {
        var path = Path()
        if inner == 0 {
            path.addEllipse(in: CGRect(
                x: center.x - outer, y: center.y - outer,
                width: outer * 2, height: outer * 2
            ))
        } else {
            path.addArc(center: center, radius: outer,
                        startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            path.addArc(center: center, radius: inner,
                        startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
            path.closeSubpath()
        }
        ctx.fill(path, with: .color(color))
    }

    private func drawArc(
        ctx: GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        fraction: Double,
        color: Color
    ) {
        let startAngle: Double = -90 // 12 o'clock
        let endAngle: Double = startAngle + 360 * fraction

        var path = Path()
        path.addArc(
            center: center,
            radius: outer,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        if inner > 0 {
            path.addArc(
                center: center,
                radius: inner,
                startAngle: .degrees(endAngle),
                endAngle: .degrees(startAngle),
                clockwise: true
            )
            path.closeSubpath()
        } else {
            path.addLine(to: center)
            path.closeSubpath()
        }
        ctx.fill(path, with: .color(color))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 24) {
        TrackerWheelView(
            tracker: TrackerType.defaults[0],
            dailyTotal: 95,
            size: 160
        )
        TrackerWheelView(
            tracker: TrackerType.defaults[1],
            dailyTotal: 75,
            size: 160
        )
    }
    .padding()
    .environmentObject(ThemeColors())
}
