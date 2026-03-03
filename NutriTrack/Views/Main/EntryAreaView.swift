import SwiftUI

// MARK: - EntryAreaView
// Presented as a bottom sheet from MainScreen.
// Contains: tracker selector, quick-add presets, numeric keypad, inline today's log.

struct EntryAreaView: View {
    let activeTrackers: [TrackerType]
    var initialTrackerID: String? = nil

    @EnvironmentObject private var todayVM: TodayViewModel
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTrackerID: String = ""
    @State private var inputText: String = ""
    @State private var editingEntry: LogEntry? = nil
    @State private var editInput: String = ""

    private var selectedTracker: TrackerType? {
        activeTrackers.first { $0.id == selectedTrackerID }
            ?? activeTrackers.first
    }

    private var todayEntries: [LogEntry] {
        guard let tracker = selectedTracker else { return [] }
        return todayVM.entries(for: tracker.id)
            .sorted { $0.safeTimestamp > $1.safeTimestamp }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Tracker selector (2+ trackers)
                if activeTrackers.count > 1 {
                    trackerTabRow
                        .padding(.top, 8)
                }

                // Quick-add preset row
                if let tracker = selectedTracker {
                    quickAddRow(tracker: tracker)
                }

                // Numeric keypad
                NumericKeypadView(inputText: $inputText) {
                    guard let tracker = selectedTracker,
                          let amount = Double(inputText), amount > 0 else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        todayVM.addEntry(trackerID: tracker.id, amount: amount)
                    }
                    inputText = ""
                    dismiss()
                }
                .padding(.horizontal, 4)

                // Inline today's log
                if !todayEntries.isEmpty, let tracker = selectedTracker {
                    todayLogSection(entries: todayEntries, tracker: tracker)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            if selectedTrackerID.isEmpty {
                selectedTrackerID = initialTrackerID ?? activeTrackers.first?.id ?? ""
            }
        }
        .onChange(of: activeTrackers) { _, newTrackers in
            if !newTrackers.contains(where: { $0.id == selectedTrackerID }) {
                selectedTrackerID = newTrackers.first?.id ?? ""
            }
        }
        .sheet(item: $editingEntry) { entry in
            if let tracker = selectedTracker {
                EditEntrySheet(entry: entry, tracker: tracker, initialInput: editInput)
                    .environmentObject(todayVM)
            }
        }
    }

    // MARK: - Tracker tab row

    private var trackerTabRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeTrackers) { tracker in
                    Button {
                        selectedTrackerID = tracker.id
                    } label: {
                        Text(tracker.displayName)
                            .font(Typography.sfPro(size: 14, weight: selectedTrackerID == tracker.id ? .semibold : .regular))
                            .foregroundStyle(selectedTrackerID == tracker.id ? Color(.systemBackground) : Color(.label))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTrackerID == tracker.id
                                    ? Color(.label)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(tracker.displayName) tracker")
                    .accessibilityAddTraits(selectedTrackerID == tracker.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Quick-add preset row

    private func quickAddRow(tracker: TrackerType) -> some View {
        let presets = settingsVM.presets(for: tracker.id)
        return Group {
            if !presets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets) { preset in
                            QuickAddPresetRow(
                                preset: preset,
                                unit: tracker.unit
                            ) {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    todayVM.addEntry(
                                        trackerID: tracker.id,
                                        amount: preset.amount
                                    )
                                }
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - Today's Log inline section

    private func todayLogSection(entries: [LogEntry], tracker: TrackerType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Log")
                .font(Typography.sfPro(size: 13, weight: .semibold))
                .foregroundStyle(Color(.secondaryLabel))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            ForEach(entries, id: \.safeID) { entry in
                logRow(entry: entry, tracker: tracker)
            }
        }
    }

    private func logRow(entry: LogEntry, tracker: TrackerType) -> some View {
        let formatted = entry.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(entry.amount))
            : String(format: "%.1f", entry.amount)

        return HStack {
            Text(DateHelpers.timeString(entry.safeTimestamp))
                .font(Typography.caption)
                .foregroundStyle(Color(.secondaryLabel))

            Spacer()

            Text("\(formatted) \(tracker.unit)")
                .font(Typography.label)
                .foregroundStyle(Color(.label))

            Button {
                editInput = formatted
                editingEntry = entry
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit entry")
            .padding(.leading, 12)

            Button {
                withAnimation {
                    todayVM.deleteEntry(entry)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.systemRed))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete entry")
            .padding(.leading, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    EntryAreaView(activeTrackers: TrackerType.defaults)
        .environmentObject(TodayViewModel())
        .environmentObject(SettingsViewModel())
}
