import SwiftUI

// MARK: - PresetsEditorView

struct PresetsEditorView: View {
    let tracker: TrackerType
    var onAdd: () -> Void
    var onEdit: (QuickAddPreset) -> Void

    @EnvironmentObject private var settingsVM: SettingsViewModel

    var presets: [QuickAddPreset] {
        settingsVM.presets(for: tracker.id)
    }

    var body: some View {
        Section(header: Text("\(tracker.displayName) Quick-Add")) {
            ForEach(presets) { preset in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let label = preset.label, !label.isEmpty {
                            Text(label)
                                .font(Typography.label)
                        }
                        Text(preset.displayText(unit: tracker.unit))
                            .font(Typography.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    Spacer()
                    Button {
                        onEdit(preset)
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit preset")
                }
            }
            .onDelete { offsets in
                settingsVM.deletePresets(for: tracker.id, at: offsets)
            }

            Button {
                onAdd()
            } label: {
                Label("Add Preset", systemImage: "plus.circle.fill")
            }
            .accessibilityLabel("Add new quick-add preset for \(tracker.displayName)")
        }
    }
}

// MARK: - PresetFormSheet

struct PresetFormSheet: View {
    let tracker: TrackerType
    let preset: QuickAddPreset?

    @EnvironmentObject private var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var label: String = ""
    @State private var amountText: String = ""

    var isEditing: Bool { preset != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Label (optional)", text: $label)
                    TextField("Amount (\(tracker.unit))", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(Text(isEditing ? "Edit Preset" : "New Preset"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Double(amountText) == nil || Double(amountText) == 0)
                }
            }
            .onAppear {
                if let preset {
                    label = preset.label ?? ""
                    amountText = preset.amount.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(preset.amount))
                        : String(format: "%.1f", preset.amount)
                }
            }
        }
    }

    private func save() {
        guard let amount = Double(amountText), amount > 0 else { return }
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let finalLabel: String? = trimmedLabel.isEmpty ? nil : trimmedLabel
        if let preset {
            settingsVM.updatePreset(preset, amount: amount, label: finalLabel)
        } else {
            settingsVM.addPreset(
                trackerID: tracker.id,
                amount: amount,
                label: finalLabel
            )
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    Form {
        PresetsEditorView(
            tracker: TrackerType.defaults[0],
            onAdd: {},
            onEdit: { _ in }
        )
        .environmentObject(SettingsViewModel())
    }
}
