import SwiftUI

// MARK: - TodayLogSheet
// Stripped-down view (no NavigationStack). Used as a standalone fallback;
// primary usage is now the inline log section embedded in EntryAreaView.

struct TodayLogSheet: View {
    let trackerID: String
    let tracker: TrackerType

    @EnvironmentObject private var todayVM: TodayViewModel
    @State private var editingEntry: LogEntry? = nil
    @State private var editInput: String = ""

    var entries: [LogEntry] {
        todayVM.entries(for: trackerID)
            .sorted { $0.safeTimestamp > $1.safeTimestamp }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                Text("No entries today")
                    .font(Typography.label)
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(entries, id: \.safeID) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateHelpers.timeString(entry.safeTimestamp))
                                    .font(Typography.caption)
                                    .foregroundStyle(Color(.secondaryLabel))

                                let formatted = entry.amount.truncatingRemainder(dividingBy: 1) == 0
                                    ? String(Int(entry.amount))
                                    : String(format: "%.1f", entry.amount)
                                Text("\(formatted) \(tracker.unit)")
                                    .font(Typography.label)
                                    .foregroundStyle(Color(.label))
                            }
                            Spacer()
                            Button {
                                editInput = entry.amount.truncatingRemainder(dividingBy: 1) == 0
                                    ? String(Int(entry.amount))
                                    : String(format: "%.1f", entry.amount)
                                editingEntry = entry
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit entry")
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { entries[$0] }
                        toDelete.forEach { todayVM.deleteEntry($0) }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(
                entry: entry,
                tracker: tracker,
                initialInput: editInput
            )
            .environmentObject(todayVM)
        }
    }
}

// MARK: - EditEntrySheet
// Internal (not private) so EntryAreaView can reference it directly.

struct EditEntrySheet: View {
    let entry: LogEntry
    let tracker: TrackerType
    let initialInput: String

    @EnvironmentObject private var todayVM: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var input: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Edit \(tracker.displayName) Entry")
                    .font(Typography.label)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.top, 8)

                NumericKeypadView(inputText: $input) {
                    if let amount = Double(input), amount > 0 {
                        todayVM.updateEntry(entry, amount: amount)
                    }
                    dismiss()
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { input = initialInput }
        }
    }
}

// MARK: - Preview

#Preview {
    TodayLogSheet(
        trackerID: "protein",
        tracker: TrackerType.defaults[0]
    )
    .environmentObject(TodayViewModel())
}
