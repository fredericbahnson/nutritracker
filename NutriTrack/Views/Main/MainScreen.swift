import SwiftUI

// MARK: - MainScreen

struct MainScreen: View {
    @EnvironmentObject private var todayVM: TodayViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var streakVM: StreakViewModel
    @EnvironmentObject private var themeColors: ThemeColors
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSettings: Bool = false
    @State private var entryTracker: TrackerType? = nil

    var body: some View {
        let activeTrackers = settingsVM.activeTrackers

        GeometryReader { geo in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                TrackerGridView(
                    trackers: activeTrackers,
                    availableSize: geo.size,
                    onTrackerTapped: { tracker in
                        entryTracker = tracker
                    }
                )
                .environmentObject(todayVM)
                .environmentObject(themeColors)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar(activeTrackers: activeTrackers)
        }
        .ignoresSafeArea(.keyboard)
        .overlay(alignment: .top) {
            if todayVM.lastError != nil {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text("Failed to save — please try again")
                        .font(Typography.label)
                    Spacer()
                    Button { todayVM.lastError = nil } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss error")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemRed).opacity(0.9))
                .foregroundStyle(.white)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: todayVM.lastError != nil)
        .sheet(isPresented: $showSettings) {
            SettingsScreen()
                .environmentObject(settingsVM)
                .environmentObject(themeColors)
        }
        .sheet(item: $entryTracker) { tracker in
            EntryAreaView(activeTrackers: activeTrackers, initialTrackerID: tracker.id)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .environmentObject(todayVM)
                .environmentObject(settingsVM)
        }
        .task { refreshStreak() }
        .onChange(of: todayVM.dailyTotals) { _, _ in refreshStreak() }
        .onChange(of: settingsVM.trackers) { _, _ in refreshStreak() }
        .onChange(of: settingsVM.streakMode) { _, _ in refreshStreak() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { refreshStreak() }
        }
    }

    private func refreshStreak() {
        let mode = settingsVM.streakMode
        let trackers = settingsVM.activeTrackers
        Task {
            await streakVM.refreshStreak(mode: mode, activeTrackers: trackers)
        }
    }

    // MARK: - Action bar

    private func actionBar(activeTrackers: [TrackerType]) -> some View {
        HStack {
            // Settings — left
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(12)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .accessibilityLabel("Settings")

            Spacer()

            // Center Log pill
            Button {
                entryTracker = activeTrackers.first
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color(.label)))
            }
            .buttonStyle(.plain)
            .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 0)
            .accessibilityLabel("Log entry")

            Spacer()

            // Streak — right
            streakBadge
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            Color(.systemBackground)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator).opacity(0.4))
                .frame(height: 0.5)
        }
    }

    // MARK: - Streak badge

    @ViewBuilder
    private var streakBadge: some View {
        if settingsVM.streakMode == .off {
            // Invisible placeholder keeps the Log pill centered
            Color.clear.frame(width: 46, height: 46)
        } else {
            Text("\(streakVM.streakCount)")
                .font(Typography.sfRounded(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color(.secondaryLabel))
                .frame(minWidth: 46, minHeight: 46)
                .accessibilityLabel("Current streak")
                .accessibilityValue(
                    streakVM.streakCount == 1 ? "1 day" : "\(streakVM.streakCount) days"
                )
        }
    }
}

// MARK: - Preview

#Preview {
    MainScreen()
        .environmentObject(TodayViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(StreakViewModel())
        .environmentObject(ThemeColors())
}
