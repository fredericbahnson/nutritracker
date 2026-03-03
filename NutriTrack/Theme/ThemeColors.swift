import SwiftUI

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255), Int(g * 255), Int(b * 255)
        )
    }
}

// MARK: - Heatmap color tokens

struct HeatmapColors {
    var green: String = "#4CAF50"
    var blue: String = "#2196F3"
    var purple: String = "#9C27B0"

    func color(for amount: Double, tracker: TrackerType) -> Color {
        guard amount > 0 else { return Color(.systemFill).opacity(0.3) }

        let minGoal = tracker.minimumGoal
        let mainGoal = tracker.mainGoal

        if amount <= minGoal {
            let opacity = min(amount / max(minGoal, 0.001), 1.0) * 0.9 + 0.1
            return Color(hex: green).opacity(opacity)
        } else if amount <= mainGoal {
            let span = mainGoal - minGoal
            let opacity = span > 0
                ? min((amount - minGoal) / span, 1.0) * 0.9 + 0.1
                : 1.0
            return Color(hex: blue).opacity(opacity)
        } else {
            let overflow = mainGoal > 0
                ? min((amount - mainGoal) / mainGoal, 1.0)
                : 1.0
            let opacity = overflow * 0.9 + 0.1
            return Color(hex: purple).opacity(opacity)
        }
    }
}

// MARK: - ThemeColors environment object

@MainActor
final class ThemeColors: ObservableObject {
    @Published var heatmap: HeatmapColors = HeatmapColors()

    // Resolve a tracker's pie color
    func pieColor(for tracker: TrackerType) -> Color {
        Color(hex: tracker.pieColor)
    }

    // Resolve a tracker's ring color
    func ringColor(for tracker: TrackerType) -> Color {
        Color(hex: tracker.ringColor)
    }

    // Resolve a tracker's bar color
    func barColor(for tracker: TrackerType) -> Color {
        Color(hex: tracker.barColor)
    }

    func heatmapColor(for amount: Double, tracker: TrackerType) -> Color {
        heatmap.color(for: amount, tracker: tracker)
    }
}
