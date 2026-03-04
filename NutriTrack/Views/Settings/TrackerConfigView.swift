import SwiftUI

// MARK: - TrackerConfigView

struct TrackerConfigView: View {
    /// Pass nil to create a new custom tracker
    let existingTracker: TrackerType?

    @EnvironmentObject private var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var unit: String = ""
    @State private var minGoalText: String = ""
    @State private var mainGoalText: String = ""
    @State private var showIconPicker = false
    @State private var pendingIconName: String? = nil

    var isEditing: Bool { existingTracker != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tracker Info")) {
                    TextField("Name (e.g., Fiber)", text: $name)
                    TextField("Unit (e.g., g)", text: $unit)
                    iconPickerRow
                }

                Section(header: Text("Goals")) {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("120", text: $minGoalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit.isEmpty ? "unit" : unit)
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(width: 48, alignment: .leading)
                    }

                    HStack {
                        Text("Main Goal")
                        Spacer()
                        TextField("160", text: $mainGoalText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit.isEmpty ? "unit" : unit)
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(width: 48, alignment: .leading)
                    }
                }
            }
            .navigationTitle(Text(isEditing ? "Edit Tracker" : "New Tracker"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if let t = existingTracker {
                    name = t.displayName
                    unit = t.unit
                    minGoalText = String(format: "%.0f", t.minimumGoal)
                    mainGoalText = String(format: "%.0f", t.mainGoal)
                    pendingIconName = t.iconName
                }
            }
            .sheet(isPresented: $showIconPicker) {
                if isEditing, let existing = existingTracker {
                    IconPickerView(
                        selectedIconName: settingsVM.tracker(for: existing.id)?.iconName,
                        onSelect: { name in
                            settingsVM.updateIcon(for: existing.id, iconName: name)
                            pendingIconName = name
                        }
                    )
                    .environmentObject(settingsVM)
                } else {
                    IconPickerView(
                        selectedIconName: pendingIconName,
                        onSelect: { name in pendingIconName = name }
                    )
                    .environmentObject(settingsVM)
                }
            }
        }
    }

    // MARK: - Icon picker row

    @ViewBuilder
    private var iconPickerRow: some View {
        let displayedIconName: String? = isEditing
            ? settingsVM.tracker(for: existingTracker?.id ?? "")?.iconName
            : pendingIconName
        let currentIcon = TrackerIconLibrary.all.first(where: { $0.id == displayedIconName })

        HStack {
            Text("Icon")
            Spacer()
            if let icon = currentIcon {
                TrackerIconLibrary.iconView(for: icon, size: 20, color: Color(.label))
                Text(icon.displayName)
                    .foregroundStyle(Color(.secondaryLabel))
            } else {
                Text("Label")
                    .foregroundStyle(Color(.secondaryLabel))
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(Color(.tertiaryLabel))
                .font(.caption)
        }
        .contentShape(Rectangle())
        .onTapGesture { showIconPicker = true }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !unit.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(minGoalText) != nil
            && Double(mainGoalText) != nil
    }

    private func save() {
        guard let minGoal = Double(minGoalText),
              let mainGoal = Double(mainGoalText) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)

        if let existing = existingTracker {
            settingsVM.updateGoals(for: existing.id, min: minGoal, main: mainGoal)
            settingsVM.updateTrackerName(trimmedName, for: existing.id)
        } else {
            settingsVM.addCustomTracker(
                name: trimmedName,
                unit: trimmedUnit,
                minGoal: minGoal,
                mainGoal: mainGoal,
                iconName: pendingIconName
            )
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    TrackerConfigView(existingTracker: nil)
        .environmentObject(SettingsViewModel())
}
