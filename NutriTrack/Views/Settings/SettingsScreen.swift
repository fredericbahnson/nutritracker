import SwiftUI

// MARK: - SettingsSheet

private enum SettingsSheet: Identifiable {
    case addTracker
    case editTracker(TrackerType)
    case addPreset(TrackerType)
    case editPreset(TrackerType, QuickAddPreset)

    var id: String {
        switch self {
        case .addTracker:                return "addTracker"
        case .editTracker(let t):        return "editTracker-\(t.id)"
        case .addPreset(let t):          return "addPreset-\(t.id)"
        case .editPreset(let t, let p):  return "editPreset-\(t.id)-\(p.id)"
        }
    }
}

// MARK: - SettingsScreen

struct SettingsScreen: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var themeColors: ThemeColors
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: SettingsSheet?

    var body: some View {
        NavigationStack {
            Form {
                trackingSection
                goalsSection
                appearanceSection
                colorsSection
                presetsSection
                aboutSection
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addTracker:
                    TrackerConfigView(existingTracker: nil)
                        .environmentObject(settingsVM)
                case .editTracker(let tracker):
                    TrackerConfigView(existingTracker: tracker)
                        .environmentObject(settingsVM)
                case .addPreset(let tracker):
                    PresetFormSheet(tracker: tracker, preset: nil)
                        .environmentObject(settingsVM)
                case .editPreset(let tracker, let preset):
                    PresetFormSheet(tracker: tracker, preset: preset)
                        .environmentObject(settingsVM)
                }
            }
        }
    }

    // MARK: - Tracking section

    private var trackingSection: some View {
        Section(header: Text("Tracking")) {
            List {
                ForEach(settingsVM.trackers.sorted { $0.displayOrder < $1.displayOrder }) { tracker in
                    HStack {
                        Toggle(
                            tracker.displayName,
                            isOn: Binding(
                                get: { tracker.isEnabled },
                                set: { _ in settingsVM.toggleTracker(id: tracker.id) }
                            )
                        )
                        .accessibilityLabel("Toggle \(tracker.displayName) tracker")

                        Button {
                            activeSheet = .editTracker(tracker)
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit \(tracker.displayName) tracker")
                    }
                }
                .onMove { source, dest in
                    settingsVM.reorderTrackers(from: source, to: dest)
                }
            }

            Button {
                activeSheet = .addTracker
            } label: {
                Label("Add Custom Tracker", systemImage: "plus.circle.fill")
            }
            .accessibilityLabel("Add a custom tracker")
        }
    }

    // MARK: - Goals section

    private var goalsSection: some View {
        ForEach(settingsVM.activeTrackers) { tracker in
            Section(header: Text("\(tracker.displayName) Goals")) {
                GoalRow(
                    label: "Minimum",
                    value: tracker.minimumGoal,
                    unit: tracker.unit
                ) { newVal in
                    settingsVM.updateGoals(
                        for: tracker.id,
                        min: newVal,
                        main: tracker.mainGoal
                    )
                }

                GoalRow(
                    label: "Main Goal",
                    value: tracker.mainGoal,
                    unit: tracker.unit
                ) { newVal in
                    settingsVM.updateGoals(
                        for: tracker.id,
                        min: tracker.minimumGoal,
                        main: newVal
                    )
                }
            }
        }
    }

    // MARK: - Appearance section

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker(selection: $settingsVM.appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            } label: {
                Text("Color Scheme")
            }
            .pickerStyle(.segmented)

            if settingsVM.activeTrackers.contains(where: { $0.id == "water" }) {
                Picker(selection: Binding(
                    get: { settingsVM.waterUnit },
                    set: { settingsVM.setWaterUnit($0) }
                )) {
                    Text("fl oz").tag(WaterUnit.flOz)
                    Text("ml").tag(WaterUnit.ml)
                } label: {
                    Text("Water Unit")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Colors section

    private var colorsSection: some View {
        ForEach(settingsVM.activeTrackers) { tracker in
            ColorPickerSection(tracker: tracker)
                .environmentObject(settingsVM)
                .environmentObject(themeColors)
        }
    }

    // MARK: - Presets section

    private var presetsSection: some View {
        ForEach(settingsVM.activeTrackers) { tracker in
            PresetsEditorView(
                tracker: tracker,
                onAdd:  { activeSheet = .addPreset(tracker) },
                onEdit: { preset in activeSheet = .editPreset(tracker, preset) }
            )
            .environmentObject(settingsVM)
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - DecimalPadTextField

private struct DecimalPadTextField: UIViewRepresentable {
    @Binding var text: String
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.keyboardType = .decimalPad
        tf.textAlignment = .right
        tf.font = UIFont.preferredFont(forTextStyle: .body)
        tf.delegate = context.coordinator

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: tf,
            action: #selector(UITextField.resignFirstResponder)
        )
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), done]
        tf.inputAccessoryView = toolbar
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if !context.coordinator.isEditing, uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DecimalPadTextField
        var isEditing = false

        init(parent: DecimalPadTextField) { self.parent = parent }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isEditing = true
            parent.onEditingChanged(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isEditing = false
            parent.text = textField.text ?? ""
            parent.onEditingChanged(false)
            parent.onCommit()
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let r = Range(range, in: current) else { return false }
            parent.text = current.replacingCharacters(in: r, with: string)
            return true
        }
    }
}

// MARK: - GoalRow

private struct GoalRow: View {
    let label: String
    let value: Double
    let unit: String
    let onCommit: (Double) -> Void

    @State private var text: String = ""
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            DecimalPadTextField(
                text: $text,
                onEditingChanged: { isEditing = $0 },
                onCommit: {
                    if let val = Double(text), val >= 0 { onCommit(val) }
                }
            )
            .frame(width: 80)
            Text(unit)
                .foregroundStyle(Color(.secondaryLabel))
                .frame(width: 52, alignment: .leading)
        }
        .onAppear {
            text = value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(format: "%.1f", value)
        }
        .onChange(of: value) { _, newValue in
            guard !isEditing else { return }
            text = newValue.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(newValue))
                : String(format: "%.1f", newValue)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsScreen()
        .environmentObject(SettingsViewModel())
        .environmentObject(ThemeColors())
}
