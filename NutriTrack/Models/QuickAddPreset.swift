import Foundation

// MARK: - QuickAddPreset

struct QuickAddPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var trackerID: String
    var amount: Double
    var label: String?

    init(id: UUID = UUID(), trackerID: String, amount: Double, label: String? = nil) {
        self.id = id
        self.trackerID = trackerID
        self.amount = amount
        self.label = label
    }

    /// Display text shown on the pill button
    func displayText(unit: String) -> String {
        if let label = label, !label.isEmpty {
            return label
        }
        let formatted = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(format: "%.1f", amount)
        return "\(formatted)\(unit)"
    }

    // MARK: - Defaults

    static let defaults: [QuickAddPreset] = [
        QuickAddPreset(trackerID: "protein", amount: 25, label: "Shake"),
        QuickAddPreset(trackerID: "protein", amount: 30, label: "Chicken"),
        QuickAddPreset(trackerID: "protein", amount: 6, label: "Egg"),
        QuickAddPreset(trackerID: "water", amount: 8, label: "Glass"),
        QuickAddPreset(trackerID: "water", amount: 16, label: "Bottle"),
        QuickAddPreset(trackerID: "water", amount: 32, label: "Large")
    ]
}

// MARK: - AppStorage helpers

extension QuickAddPreset {
    static func load(from data: Data) -> [QuickAddPreset]? {
        try? JSONDecoder().decode([QuickAddPreset].self, from: data)
    }

    static func encode(_ presets: [QuickAddPreset]) -> Data? {
        try? JSONEncoder().encode(presets)
    }
}
