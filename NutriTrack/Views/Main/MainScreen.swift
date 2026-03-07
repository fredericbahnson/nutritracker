import SwiftUI

// MARK: - MainScreen

struct MainScreen: View {
    @EnvironmentObject private var todayVM: TodayViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var themeColors: ThemeColors

    @State private var showSettings: Bool = false
    @State private var showHistory: Bool = false
    @State private var showEntry: Bool = false
    @State private var entryInitialTrackerID: String? = nil

    var body: some View {
        let activeTrackers = settingsVM.activeTrackers

        GeometryReader { geo in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                TrackerGridView(
                    trackers: activeTrackers,
                    availableSize: geo.size,
                    onTrackerTapped: { tracker in
                        entryInitialTrackerID = tracker.id
                        showEntry = true
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
        .sheet(isPresented: $showHistory) {
            HistoryScreen()
                .environmentObject(settingsVM)
                .environmentObject(themeColors)
        }
        .sheet(isPresented: $showEntry) {
            EntryAreaView(activeTrackers: activeTrackers, initialTrackerID: entryInitialTrackerID)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .environmentObject(todayVM)
                .environmentObject(settingsVM)
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
                entryInitialTrackerID = nil
                showEntry = true
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

            // History — right
            Button {
                showHistory = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(12)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .accessibilityLabel("History")
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


}

// MARK: - Preview

#Preview {
    MainScreen()
        .environmentObject(TodayViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(ThemeColors())
}
