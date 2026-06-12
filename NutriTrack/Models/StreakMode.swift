import SwiftUI

// MARK: - StreakMode

/// What it takes for a day to count toward the streak.
enum StreakMode: String, CaseIterable, Identifiable {
    case off
    case daysTracked
    case minimumGoals
    case mainGoals

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .off:          return "Off"
        case .daysTracked:  return "Days Tracked"
        case .minimumGoals: return "Minimum Goals"
        case .mainGoals:    return "Main Goals"
        }
    }

    var footerDescription: LocalizedStringKey {
        switch self {
        case .off:          return "No streak is shown."
        case .daysTracked:  return "Counts consecutive days with at least one entry logged."
        case .minimumGoals: return "Counts consecutive days on which every active tracker reached its minimum goal."
        case .mainGoals:    return "Counts consecutive days on which every active tracker reached its main goal."
        }
    }
}
