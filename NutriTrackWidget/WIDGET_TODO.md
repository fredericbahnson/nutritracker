# Widget Implementation TODO

This file documents what needs to be done to fully implement the NutriTrack widget.

## Prerequisites

### App Group (already configured)
- App group `group.com.nutritrack` is configured on both `NutriTrack` and `NutriTrackWidget` targets.
- The Core Data store uses the App Group container URL:
  ```swift
  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nutritrack")
  ```

## Steps to Implement

### 1. Shared Core Data access
- The `CoreDataStack` in the main app already writes to the App Group container.
- In the widget `Provider`, instantiate a read-only `NSPersistentContainer` pointing to the same store URL.
- Use a background context to avoid blocking the widget timeline thread.

### 2. Widget entry model
```swift
struct NutriTrackEntry: TimelineEntry {
    let date: Date
    let trackerSnapshots: [TrackerSnapshot]
}

struct TrackerSnapshot {
    let trackerID: String
    let displayName: String
    let unit: String
    let dailyTotal: Double
    let minimumGoal: Double
    let mainGoal: Double
    let pieColorHex: String
    let ringColorHex: String
}
```

### 3. Provider implementation
- In `getTimeline`, fetch today's `LogEntry` records grouped by `trackerID`.
- Read active trackers from `UserDefaults(suiteName: "group.com.nutritrack")`.
- Build a `Timeline` with one entry per hour (or at day-reset midnight).
- Refresh policy: `.after(nextMidnight)` so the widget resets at midnight.

### 4. Entry view
- Small widget: show a single mini `TrackerWheelView` (Canvas-based) for the first active tracker.
- Medium widget: show two mini wheels side by side.
- Reuse the `Color(hex:)` extension from `ThemeColors.swift`.

### 5. Deep link
- On widget tap, open the main app to the correct tracker using a URL scheme:
  `nutritrack://tracker/<trackerID>`
- Handle in `NutriTrackApp.onOpenURL`.

### 6. Shared UserDefaults
- Move all `@AppStorage` keys to `UserDefaults(suiteName: "group.com.nutritrack")` in `SettingsViewModel`.
- Widget reads tracker configs from the same suite.

## Timeline Refresh Strategy
- Refresh at: start of next day (midnight local time) to reset daily totals display.
- Additionally, use `WidgetCenter.shared.reloadAllTimelines()` in `TodayViewModel.addEntry/deleteEntry/updateEntry` to reflect live changes.
