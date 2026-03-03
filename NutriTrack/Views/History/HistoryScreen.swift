import SwiftUI

// MARK: - HistoryScreen

struct HistoryScreen: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var themeColors: ThemeColors
    @Environment(\.dismiss) private var dismiss

    @StateObject private var historyVM = HistoryViewModel()

    @State private var isListView: Bool = false
    @State private var viewMode: ViewMode = .weekly

    private enum ViewMode: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    private var selectedTracker: TrackerType? {
        settingsVM.tracker(for: historyVM.selectedTrackerID)
            ?? settingsVM.activeTrackers.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tracker selector
                if settingsVM.activeTrackers.count > 1 {
                    trackerSelector
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                // Weekly / Monthly picker (only when not in list view)
                if !isListView {
                    Picker("View", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                Divider()

                // Content
                if let tracker = selectedTracker {
                    Group {
                        if isListView {
                            HistoryListView(
                                tracker: tracker,
                                dailyTotals: historyVM.dailyTotals
                            )
                            .environmentObject(themeColors)
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    switch viewMode {
                                    case .weekly:
                                        WeeklyHeatmapView(
                                            tracker: tracker,
                                            dailyTotals: historyVM.dailyTotals
                                        )
                                        .environmentObject(themeColors)
                                        .padding(.top, 8)
                                    case .monthly:
                                        MonthlyHeatmapView(
                                            tracker: tracker,
                                            dailyTotals: historyVM.dailyTotals
                                        )
                                        .environmentObject(themeColors)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                    }
                    .task(id: historyVM.selectedTrackerID) {
                        await loadData(for: tracker)
                    }
                } else {
                    ContentUnavailableView(
                        "No Trackers Active",
                        systemImage: "chart.pie",
                        description: Text("Enable trackers in Settings first.")
                    )
                }
            }
            .navigationTitle(Text("History"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isListView.toggle()
                    } label: {
                        Image(systemName: isListView ? "chart.bar.fill" : "list.bullet")
                            .font(.system(size: 18))
                    }
                    .accessibilityLabel(isListView ? "Switch to heatmap view" : "Switch to list view")
                }

                ToolbarItem(placement: .bottomBar) { Spacer() }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18))
                    }
                    .accessibilityLabel("Return to main screen")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let first = settingsVM.activeTrackers.first {
                    historyVM.selectedTrackerID = first.id
                }
            }
        }
    }

    // MARK: - Tracker selector

    private var trackerSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(settingsVM.activeTrackers) { tracker in
                    Button {
                        historyVM.selectedTrackerID = tracker.id
                    } label: {
                        Text(tracker.displayName)
                            .font(Typography.sfPro(
                                size: 14,
                                weight: historyVM.selectedTrackerID == tracker.id ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                historyVM.selectedTrackerID == tracker.id
                                    ? Color(.systemBackground)
                                    : Color(.label)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                historyVM.selectedTrackerID == tracker.id
                                    ? Color(.label)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show \(tracker.displayName) history")
                    .accessibilityAddTraits(historyVM.selectedTrackerID == tracker.id ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Data loading

    private func loadData(for tracker: TrackerType) async {
        // Load 1 year of data
        let end = Date()
        let start = Calendar.current.date(byAdding: .year, value: -1, to: end) ?? end
        await historyVM.fetchDailyTotals(from: start, to: end)
    }
}

// MARK: - Preview

#Preview {
    HistoryScreen()
        .environmentObject(SettingsViewModel())
        .environmentObject(ThemeColors())
}
