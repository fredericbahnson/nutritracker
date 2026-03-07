import SwiftUI

// MARK: - ColorPickerSection

struct ColorPickerSection: View {
    let tracker: TrackerType

    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var themeColors: ThemeColors

    @State private var pieColor: Color
    @State private var ringColor: Color
    @State private var barColor: Color
    @State private var labelColor: Color

    init(tracker: TrackerType) {
        self.tracker = tracker
        _pieColor   = State(initialValue: Color(hex: tracker.pieColor))
        _ringColor  = State(initialValue: Color(hex: tracker.ringColor))
        _barColor   = State(initialValue: Color(hex: tracker.barColor))
        _labelColor = State(initialValue: tracker.labelColor == "adaptive" ? .white : Color(hex: tracker.labelColor))
    }

    var body: some View {
        Section(header: Text("\(tracker.displayName) Colors")) {
            ColorPicker(selection: $pieColor, supportsOpacity: false) {
                Label("Wheel", systemImage: "circle.fill")
            }
            .onChange(of: pieColor) { _, _ in save() }

            ColorPicker(selection: $ringColor, supportsOpacity: false) {
                Label("Ring", systemImage: "circle")
            }
            .onChange(of: ringColor) { _, _ in save() }

            ColorPicker(selection: $barColor, supportsOpacity: false) {
                Label("Bar", systemImage: "rectangle.fill")
            }
            .onChange(of: barColor) { _, _ in save() }

            ColorPicker(selection: $labelColor, supportsOpacity: false) {
                Label("Label & Icon Color", systemImage: "textformat")
            }
            .onChange(of: labelColor) { _, _ in save() }

            Button {
                settingsVM.resetColors(for: tracker.id)
                if let updated = settingsVM.tracker(for: tracker.id) {
                    pieColor   = Color(hex: updated.pieColor)
                    ringColor  = Color(hex: updated.ringColor)
                    barColor   = Color(hex: updated.barColor)
                    labelColor = updated.labelColor == "adaptive" ? .white : Color(hex: updated.labelColor)
                }
            } label: {
                Label("Restore Defaults", systemImage: "arrow.uturn.backward")
            }
        }
    }

    private func save() {
        settingsVM.updateColors(
            for: tracker.id,
            pie: pieColor.toHex(),
            ring: ringColor.toHex(),
            bar: barColor.toHex()
        )
        settingsVM.updateLabelColor(for: tracker.id, labelColor: labelColor.toHex())
    }
}

// MARK: - Preview

#Preview {
    Form {
        ColorPickerSection(tracker: TrackerType.defaults[0])
            .environmentObject(SettingsViewModel())
            .environmentObject(ThemeColors())
    }
}
