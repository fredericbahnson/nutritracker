import Foundation
import SwiftUI

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - AppStorage-backed published properties

    @AppStorage("trackerConfigs") private var trackerConfigsData: Data = Data()
    @AppStorage("quickAddPresets") private var quickAddPresetsData: Data = Data()
    @AppStorage("waterUnit") private var waterUnitRaw: String = WaterUnit.flOz.rawValue
    @AppStorage("appearanceMode") var appearanceMode: String = "system"
    @AppStorage("dayResetHour") var dayResetHour: Int = 0

    @Published var trackers: [TrackerType] = []
    @Published var presets: [QuickAddPreset] = []
    @Published var waterUnit: WaterUnit = .flOz

    init() {
        loadAll()
    }

    // MARK: - Load

    private func loadAll() {
        trackers = TrackerType.load(from: trackerConfigsData) ?? TrackerType.defaults
        presets = QuickAddPreset.load(from: quickAddPresetsData) ?? QuickAddPreset.defaults
        waterUnit = WaterUnit(rawValue: waterUnitRaw) ?? .flOz

        // Migrate stale icon names from previous builds
        if trackers.contains(where: { $0.iconName == "dna" || $0.iconName == "figure.strengthtraining.traditional" }) {
            trackers = trackers.map { tracker in
                var t = tracker
                if t.iconName == "dna" || t.iconName == "figure.strengthtraining.traditional" {
                    t.iconName = "custom.helix"
                }
                return t
            }
            saveTrackers()
        }

        // Update water unit display on trackers
        updateWaterUnitDisplay()
    }

    // MARK: - Persistence

    private func saveTrackers() {
        if let data = TrackerType.encode(trackers) {
            trackerConfigsData = data
        }
    }

    private func savePresets() {
        if let data = QuickAddPreset.encode(presets) {
            quickAddPresetsData = data
        }
    }

    // MARK: - Active trackers (ordered, enabled)

    var activeTrackers: [TrackerType] {
        trackers
            .filter { $0.isEnabled }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    // MARK: - Tracker CRUD

    func toggleTracker(id: String) {
        guard let idx = trackers.firstIndex(where: { $0.id == id }) else { return }
        trackers[idx].isEnabled.toggle()
        saveTrackers()
    }

    func updateGoals(for id: String, min: Double, main: Double) {
        guard let idx = trackers.firstIndex(where: { $0.id == id }) else { return }
        trackers[idx].minimumGoal = min
        trackers[idx].mainGoal = main
        saveTrackers()
    }

    func updateColors(
        for id: String,
        pie: String,
        ring: String,
        bar: String
    ) {
        guard let idx = trackers.firstIndex(where: { $0.id == id }) else { return }
        trackers[idx].pieColor = pie
        trackers[idx].ringColor = ring
        trackers[idx].barColor = bar
        saveTrackers()
    }

    func updateIcon(for trackerID: String, iconName: String?) {
        guard let idx = trackers.firstIndex(where: { $0.id == trackerID }) else { return }
        trackers[idx].iconName = iconName
        saveTrackers()
    }

    func updateLabelColor(for trackerID: String, labelColor: String) {
        guard let idx = trackers.firstIndex(where: { $0.id == trackerID }) else { return }
        trackers[idx].labelColor = labelColor
        saveTrackers()
    }

    func addCustomTracker(
        name: String,
        unit: String,
        minGoal: Double,
        mainGoal: Double,
        iconName: String? = nil
    ) {
        let newID = name.lowercased().replacingOccurrences(of: " ", with: "_")
        let newOrder = (trackers.map(\.displayOrder).max() ?? -1) + 1
        let tracker = TrackerType(
            id: newID,
            displayName: name,
            unit: unit,
            isBuiltIn: false,
            minimumGoal: minGoal,
            mainGoal: mainGoal,
            displayOrder: newOrder,
            isEnabled: true,
            pieColor: "#8E44AD",
            ringColor: "#BB8FCE",
            barColor: "#6C3483",
            iconName: iconName,
            labelColor: "#FFFFFF"
        )
        trackers.append(tracker)
        saveTrackers()
    }

    func removeCustomTracker(id: String) {
        trackers.removeAll { $0.id == id && !$0.isBuiltIn }
        saveTrackers()
    }

    func reorderTrackers(from source: IndexSet, to destination: Int) {
        var active = activeTrackers
        active.move(fromOffsets: source, toOffset: destination)
        for (order, tracker) in active.enumerated() {
            if let idx = trackers.firstIndex(where: { $0.id == tracker.id }) {
                trackers[idx].displayOrder = order
            }
        }
        saveTrackers()
    }

    func updateTrackerName(_ name: String, for id: String) {
        guard let idx = trackers.firstIndex(where: { $0.id == id }) else { return }
        trackers[idx].displayName = name
        saveTrackers()
    }

    func tracker(for id: String) -> TrackerType? {
        trackers.first { $0.id == id }
    }

    // MARK: - Water unit

    func setWaterUnit(_ unit: WaterUnit) {
        waterUnit = unit
        waterUnitRaw = unit.rawValue
        updateWaterUnitDisplay()
        saveTrackers()
    }

    private func updateWaterUnitDisplay() {
        for idx in trackers.indices where trackers[idx].id == "water" {
            trackers[idx].unit = waterUnit.displayName
        }
    }

    // MARK: - Presets

    func presets(for trackerID: String) -> [QuickAddPreset] {
        presets.filter { $0.trackerID == trackerID }
    }

    func addPreset(trackerID: String, amount: Double, label: String?) {
        let preset = QuickAddPreset(trackerID: trackerID, amount: amount, label: label)
        presets.append(preset)
        savePresets()
    }

    func updatePreset(_ preset: QuickAddPreset, amount: Double, label: String?) {
        guard let idx = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[idx].amount = amount
        presets[idx].label = label
        savePresets()
    }

    func deletePresets(for trackerID: String, at offsets: IndexSet) {
        let filtered = presets(for: trackerID)
        let toRemove = offsets.map { filtered[$0].id }
        presets.removeAll { toRemove.contains($0.id) }
        savePresets()
    }

    func deletePreset(_ preset: QuickAddPreset) {
        presets.removeAll { $0.id == preset.id }
        savePresets()
    }
}
