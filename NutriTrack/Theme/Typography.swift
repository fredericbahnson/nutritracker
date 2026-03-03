import SwiftUI

// MARK: - Typography

enum Typography {
    /// SF Rounded — used for all numeric displays
    static func sfRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// SF Pro — used for body text and labels
    static func sfPro(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // Predefined scales
    static let largeNumber: Font = sfRounded(size: 36, weight: .bold)
    static let mediumNumber: Font = sfRounded(size: 24, weight: .semibold)
    static let smallNumber: Font = sfRounded(size: 14, weight: .medium)
    static let unit: Font = sfPro(size: 13, weight: .regular)
    static let label: Font = sfPro(size: 15, weight: .medium)
    static let caption: Font = sfPro(size: 12, weight: .regular)
    static let keypadDigit: Font = sfRounded(size: 28, weight: .medium)
    static let keypadDisplay: Font = sfRounded(size: 48, weight: .bold)
}
