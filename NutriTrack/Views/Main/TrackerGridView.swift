import SwiftUI

// MARK: - TrackerGridView

struct TrackerGridView: View {
    let trackers: [TrackerType]
    let availableSize: CGSize
    let onTrackerTapped: (TrackerType) -> Void

    @EnvironmentObject private var todayVM: TodayViewModel
    @EnvironmentObject private var themeColors: ThemeColors

    var body: some View {
        switch trackers.count {
        case 1:
            singleLayout
        case 2:
            twoLayout
        case 3:
            threeLayout
        case 4:
            fourLayout
        default:
            if trackers.isEmpty {
                emptyState
            } else {
                scrollingLayout
            }
        }
    }

    // MARK: - Layouts

    private var singleLayout: some View {
        let wheelSize = min(availableSize.width * 0.8, availableSize.height * 0.8)
        return TrackerWheelView(
            tracker: trackers[0],
            dailyTotal: todayVM.dailyTotal(for: trackers[0].id),
            size: wheelSize,
            onTap: { onTrackerTapped(trackers[0]) }
        )
        .environmentObject(themeColors)
    }

    private var twoLayout: some View {
        let wheelSize = min(availableSize.width * 0.7, availableSize.height * 0.44)
        return VStack(spacing: 16) {
            ForEach(trackers) { tracker in
                TrackerWheelView(
                    tracker: tracker,
                    dailyTotal: todayVM.dailyTotal(for: tracker.id),
                    size: wheelSize,
                    onTap: { onTrackerTapped(tracker) }
                )
                .environmentObject(themeColors)
            }
        }
    }

    private var threeLayout: some View {
        let topSize = min(availableSize.width * 0.55, availableSize.height * 0.44)
        let bottomSize = min(availableSize.width * 0.4, availableSize.height * 0.38)
        return VStack(spacing: 12) {
            // Top: first in displayOrder
            TrackerWheelView(
                tracker: trackers[0],
                dailyTotal: todayVM.dailyTotal(for: trackers[0].id),
                size: topSize,
                onTap: { onTrackerTapped(trackers[0]) }
            )
            .environmentObject(themeColors)

            // Bottom: next two side by side
            HStack(spacing: 24) {
                ForEach(trackers.dropFirst()) { tracker in
                    TrackerWheelView(
                        tracker: tracker,
                        dailyTotal: todayVM.dailyTotal(for: tracker.id),
                        size: bottomSize,
                        onTap: { onTrackerTapped(tracker) }
                    )
                    .environmentObject(themeColors)
                }
            }
        }
    }

    private var fourLayout: some View {
        let wheelSize = min(availableSize.width * 0.42, availableSize.height * 0.44)
        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(trackers.prefix(2)) { tracker in
                    TrackerWheelView(
                        tracker: tracker,
                        dailyTotal: todayVM.dailyTotal(for: tracker.id),
                        size: wheelSize,
                        onTap: { onTrackerTapped(tracker) }
                    )
                    .environmentObject(themeColors)
                }
            }
            HStack(spacing: 16) {
                ForEach(Array(trackers.dropFirst(2))) { tracker in
                    TrackerWheelView(
                        tracker: tracker,
                        dailyTotal: todayVM.dailyTotal(for: tracker.id),
                        size: wheelSize,
                        onTap: { onTrackerTapped(tracker) }
                    )
                    .environmentObject(themeColors)
                }
            }
        }
    }

    private var scrollingLayout: some View {
        let wheelSize = min(availableSize.width * 0.42, availableSize.height * 0.44)
        return ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(trackers) { tracker in
                    TrackerWheelView(
                        tracker: tracker,
                        dailyTotal: todayVM.dailyTotal(for: tracker.id),
                        size: wheelSize,
                        onTap: { onTrackerTapped(tracker) }
                    )
                    .environmentObject(themeColors)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Trackers Active",
            systemImage: "chart.pie",
            description: Text("Enable trackers in Settings to start logging.")
        )
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geo in
        TrackerGridView(
            trackers: TrackerType.defaults,
            availableSize: CGSize(
                width: geo.size.width,
                height: geo.size.height * 0.66
            ),
            onTrackerTapped: { _ in }
        )
        .environmentObject(TodayViewModel())
        .environmentObject(ThemeColors())
    }
}
