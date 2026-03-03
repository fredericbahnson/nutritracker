# CLAUDE.md — NutriTrack iOS App

> This document is the single source of truth for Claude Code building the NutriTrack app. Follow it precisely. When in doubt, ask rather than assume.

---

## 1. Project Overview

NutriTrack is a minimalist iOS app for tracking daily intake goals (protein, water, and extensible to additional nutrients). It is fast, polished, and built for one-handed daily use. Its defining features are a beautiful visual progress display, a configurable goal system with dual thresholds (minimum + main), a flexible history heatmap, and an architecture that can support up to ~6 tracker types without redesign.

---

## 2. Tech Stack

| Layer | Choice |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Persistence | Core Data |
| Minimum iOS | iOS 17 |
| Widget (future) | WidgetKit (architecture must not block this — stub the extension target) |
| No third-party dependencies | All libraries must be from Apple's SDK |

**Do not use UIKit directly.** Use SwiftUI representables only if SwiftUI cannot accomplish something natively.

---

## 3. Architecture

### 3.1 Core Principles

- **Tracker-generic architecture from day one.** Every model, view, and piece of logic must be written to support N tracker types, not just protein and water. Adding a new tracker type in the future should require only: (a) adding an entry to the `TrackerType` registry and (b) Core Data migration — no view rewrites.
- **AppStorage + Core Data split:** User preferences and settings live in `@AppStorage` (UserDefaults). Historical log entries live in Core Data.
- **No hardcoded colors anywhere.** Every color in the app must reference a named token from the theme/settings system.

### 3.2 Data Model

#### TrackerType (registry, not Core Data entity)
```swift
struct TrackerType: Identifiable, Codable {
    let id: String          // e.g. "protein", "water", "fiber"
    let displayName: String // e.g. "Protein"
    let unit: String        // e.g. "g", "fl oz", "ml"
    let isBuiltIn: Bool
    var minimumGoal: Double
    var mainGoal: Double
    var displayOrder: Int
    var isEnabled: Bool
    // Color tokens (stored as hex strings, resolved at render time)
    var pieColor: String
    var ringColor: String
    var barColor: String
}
```

Built-in types at launch: `protein`, `water`. Unit for water is user-selectable (fl oz or ml) and stored in settings; the model always stores values in the canonical unit and converts for display.

#### LogEntry (Core Data entity)
```
LogEntry
  - id: UUID
  - trackerID: String      // matches TrackerType.id
  - amount: Double          // in canonical unit
  - timestamp: Date
  - note: String?           // optional, reserved for future use
```

#### DailyTotal (computed, not stored)
Aggregate LogEntry by trackerID + calendar day. Never cache these — always derive from LogEntry queries. Day boundary = midnight local time.

### 3.3 Settings (AppStorage keys)

```
activeTrackers: [String]           // ordered array of enabled trackerType IDs
displayOrder: [String]             // user-chosen display order for main screen
waterUnit: "floz" | "ml"
appearanceMode: "system" | "light" | "dark"
trackerConfigs: Data               // JSON-encoded [TrackerType] for goals + colors
quickAddPresets: Data              // JSON-encoded [QuickAddPreset]
dayResetHour: Int = 0             // always 0 (midnight), kept as setting for future extensibility
```

### 3.4 Default Values (pre-loaded on first launch)

```swift
// Protein
minimumGoal: 120 g
mainGoal: 160 g
pieColor: "#FF6B35"    // warm orange (placeholder — choose a polished default)
ringColor: "#FFB347"
barColor: "#FF8C00"

// Water
minimumGoal: 80 fl oz
mainGoal: 120 fl oz
pieColor: "#4FC3F7"    // light blue
ringColor: "#0288D1"
barColor: "#01579B"
```

Replace placeholder colors with a genuinely attractive, accessible palette before finalizing.

---

## 4. Main Screen

### 4.1 Layout Overview

The main screen has three zones:
1. **Progress display** (top, ≥66% of screen height) — tracker wheels
2. **Entry area** (bottom, ~20% of screen height) — input controls
3. **Nav icons** — bottom-left (settings) and bottom-right (history), always visible

### 4.2 Progress Display — Single Tracker

When only one tracker is active, its wheel fills the entire progress zone, centered.

### 4.3 Progress Display — Two Trackers

Stack vertically, equal height, each taking 50% of the progress zone. User can set which appears on top (stored in `displayOrder`).

### 4.4 Progress Display — Three Trackers

"Pyramid" layout:
- Row 1: 1 wheel, ~40% width of zone, slightly larger than the others
- Row 2: 2 wheels side by side, each ~30% width of zone
- The single top wheel is the first item in `displayOrder`. User controls order.

### 4.5 Progress Display — Four Trackers

2×2 grid, equal size. User controls order.

### 4.6 The Tracker Wheel Component

Each tracker is rendered as a single reusable `TrackerWheelView` that accepts a `TrackerType` and `DailyTotal`.

**Visual layers (outermost to innermost — all rendered as SwiftUI Canvas or `Path`):**

1. **Overflow bar** — a narrow vertical bar on the right side of the wheel. Fills from bottom to top. Empty at `intake == mainGoal`, full at `intake == 2 × mainGoal`. Color: `barColor`. Capped visually at top (does not overflow the bar element).

2. **Ring** — annular ring surrounding the pie. Begins filling (clockwise from 12 o'clock) when `intake > minimumGoal`. Reaches 100% fill when `intake == mainGoal`. Color: `ringColor`. Show as empty/unfilled track when at 0%.

3. **Pie** — filled circle. Fills clockwise from 12 o'clock. Reaches 100% when `intake == minimumGoal`. Color: `pieColor`. Show as empty/unfilled track when at 0%.

4. **Center label** — inside the pie, show current intake amount (number + unit) and percentage of main goal. Typography: SF Rounded, large number, small unit/percent below.

All three fill animations should be smooth (`withAnimation(.easeInOut)`). All fill values must be clamped to [0, 1] — never overflow the visual element.

**Sizing rules:**
- Pie occupies ~55% of the wheel diameter
- Ring occupies ~20% of wheel diameter (annular width)
- A small gap (2pt) separates pie from ring
- Overflow bar: width ~8pt, height = wheel diameter, positioned 8pt to the right of the ring's outer edge

### 4.7 Entry Area

**One active tracker:** Show a single number entry field with the tracker name and unit as a label. Tapping opens a custom numeric keypad.

**Two or more active trackers:** Show a segmented control or pill-style tab row above the entry field to select which tracker to log. Only one tracker is "active for entry" at a time.

**Keypad behavior:**
- Use a custom SwiftUI numeric keypad (not the system keyboard) for speed and consistency.
- Support decimal input (one decimal place).
- Show the number being entered in large type above the keypad.
- "Log" button submits the entry. "Clear" resets the field. A small backspace button for correcting digits.
- The entry area must never be obscured by the keypad. Use `ScrollViewReader` or `padding` to keep the number visible.

**Quick-add presets:**
- Display as a horizontally scrollable row of pill buttons above the keypad, filtered to the currently selected tracker.
- Tapping a preset adds that amount instantly (no confirmation needed) and provides a subtle success animation on the wheel.
- Presets are configured in Settings.

---

## 5. Settings Screen

Accessed via a small gear icon (SF Symbol: `gearshape.fill`) in the bottom-left corner of the main screen. Presented as a sheet or pushed navigation view.

### 5.1 Sections

**Tracking**
- Toggle on/off for each available tracker type (built-in and custom)
- Display order drag-reorder for active trackers
- "Add custom tracker" button (opens a form: name, unit, min goal, main goal)

**Goals** (one section per active tracker)
- Minimum goal (numeric field + unit)
- Main goal (numeric field + unit)

**Appearance**
- Appearance mode: System / Light / Dark (segmented control)
- Water unit: fl oz / ml (segmented control, only shown when water is active)
- Per-tracker color settings: three color pickers (pie, ring, bar) for each active tracker. Use SwiftUI `ColorPicker`.

**Quick-Add Presets** (one section per active tracker)
- List of presets with amount + label
- Add / edit / delete presets
- Each preset: label (optional), amount (Double), trackerID

**About**
- App version

---

## 6. History Screen

Accessed via a small calendar icon (SF Symbol: `calendar`) in the bottom-right corner of the main screen.

### 6.1 Layout

- **Top:** Tracker selector — a segmented control or pill tabs showing all active tracker names. Determines which tracker's data is displayed.
- **Middle:** Heatmap display (see 6.2)
- **Bottom-left:** List icon (SF Symbol: `list.bullet`) — switches to list view
- **Bottom-right:** Home icon (SF Symbol: `house.fill`) — returns to main screen

### 6.2 Heatmap

Each day is a colored square. Color is determined by intake relative to goals:

| Intake range | Color behavior |
|---|---|
| 0 | Empty / background color |
| 0 < intake ≤ minimumGoal | Green, opacity scales from ~10% to 100% |
| minimumGoal < intake ≤ mainGoal | Blue, opacity scales from ~10% to 100% |
| intake > mainGoal | Purple, opacity scales from ~10% to ~100% (capped at `2 × mainGoal`) |

**All three colors (green, blue, purple) must be theme tokens — not hardcoded.** Default values: green `#4CAF50`, blue `#2196F3`, purple `#9C27B0`.

The heatmap does NOT show individual log entries when tapped — it shows daily totals only.

### 6.3 Weekly View

- 7 squares across the full width of the screen.
- Day labels (M T W T F S S) above each column.
- Current week is the rightmost week visible on first load.
- **Swipe right** scrolls back in time (previous weeks). Swipe left scrolls forward. Use `TabView` with `PageTabViewStyle` or a custom gesture-driven `ScrollView` — must feel smooth and native.
- Dates are shown below each square (e.g., "3", "4").
- Today's square has a subtle outline or indicator.

### 6.4 Monthly View

- Full calendar month grid (Mon–Sun columns, rows of weeks).
- Month + year shown as header.
- **Swipe up** = previous month. **Swipe down** = next month. Use vertical paging.
- Days outside the current month are shown dimmed or empty.

### 6.5 View Selector

A simple segmented control at the top switches between Weekly and Monthly views. The tracker selector sits above this.

### 6.6 List View

Replaces the heatmap with a vertically scrolling list. Each row: date, total intake, unit, and a small colored dot matching the heatmap color tier. Most recent at top. Tapping a row does nothing (no detail view — totals only).

---

## 7. Visual Design & Theming

### 7.1 Design Principles

- **Minimalist:** Maximum whitespace. No decorative elements. Let the tracker wheels carry the visual weight.
- **SF Rounded** for all numeric displays. **SF Pro** for body/labels. Never specify a font that isn't available on-device.
- **No hardcoded colors anywhere.** Use a `ThemeColors` environment object that reads from settings.
- Corner radii, spacing, and padding must use a consistent scale (e.g., 4/8/16/24pt).

### 7.2 Dark Mode

All background, surface, and text colors must have light and dark variants. Use SwiftUI's `Color` semantic colors (`Color(.systemBackground)`, `Color(.label)`, etc.) wherever possible. Override appearance via `.preferredColorScheme()` at the root view based on the user's setting.

### 7.3 Animations

- Wheel fills animate on intake logging.
- Preset pill tap: brief scale + opacity pulse.
- Screen transitions: use default SwiftUI transitions (`.slide`, `.opacity`) — no custom third-party animations.
- Keep all animations under 400ms. Never block user input during animation.

---

## 8. Quick-Add Presets — Detail

```swift
struct QuickAddPreset: Identifiable, Codable {
    let id: UUID
    var trackerID: String
    var amount: Double
    var label: String?       // e.g. "Water bottle", "Protein shake"
}
```

Presets are ordered per tracker. In the entry area, show the label if present, otherwise show the amount + unit (e.g. "30g").

---

## 9. Log Entry Correction (Today's Log)

On the main screen's entry area, include a small "history" icon (SF Symbol: `clock.arrow.circlepath`) that opens a sheet showing today's log entries for the currently selected tracker, as a list:

- Timestamp (e.g., "2:34 PM")
- Amount + unit
- Swipe-to-delete to remove an entry
- Tap to edit (opens a simple amount editor with the numeric keypad)

Deleting or editing an entry immediately recalculates today's total and updates the wheel.

---

## 10. Widget (Stub Only — Do Not Implement Fully)

Create a WidgetKit extension target in Xcode with:
- A placeholder `Provider` and `EntryView` that shows "Widget coming soon"
- The app group entitlement configured so Core Data can be shared with the widget in a future version
- Document what needs to be done to fully implement the widget in a `WIDGET_TODO.md` file

---

## 11. File & Folder Structure

```
NutriTrack/
├── App/
│   ├── NutriTrackApp.swift
│   └── AppDelegate.swift (if needed)
├── Models/
│   ├── TrackerType.swift
│   ├── QuickAddPreset.swift
│   ├── LogEntry+CoreData (generated)
│   └── NutriTrack.xcdatamodeld
├── ViewModels/
│   ├── TodayViewModel.swift
│   ├── HistoryViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Main/
│   │   ├── MainScreen.swift
│   │   ├── TrackerWheelView.swift
│   │   ├── EntryAreaView.swift
│   │   ├── QuickAddPresetRow.swift
│   │   └── TodayLogSheet.swift
│   ├── History/
│   │   ├── HistoryScreen.swift
│   │   ├── HeatmapView.swift
│   │   ├── WeeklyHeatmapView.swift
│   │   ├── MonthlyHeatmapView.swift
│   │   └── HistoryListView.swift
│   └── Settings/
│       ├── SettingsScreen.swift
│       ├── TrackerConfigView.swift
│       ├── ColorPickerSection.swift
│       └── PresetsEditorView.swift
├── Theme/
│   ├── ThemeColors.swift
│   └── Typography.swift
├── Utilities/
│   ├── DateHelpers.swift
│   └── UnitConversion.swift
└── NutriTrackWidget/
    ├── NutriTrackWidget.swift
    └── WIDGET_TODO.md
```

---

## 12. Engineering Constraints & Rules

1. **No hardcoded colors.** Every `Color(...)` call must trace back to a settings value or a SwiftUI semantic color.
2. **No hardcoded tracker types.** All views that render per-tracker must work for any N ≥ 1 trackers using loops/`ForEach`, not switch statements with `case .protein`.
3. **Core Data must be accessed only through ViewModels**, never directly from Views.
4. **All user-facing strings must use `LocalizedStringKey`** (foundation for future localization, even if only English ships now).
5. **Accessibility:** Every tappable element must have an `.accessibilityLabel`. Wheels must describe their state in `.accessibilityValue` (e.g., "95 grams, 59% of main goal").
6. **No force unwraps** (`!`) outside of test code.
7. **Preview providers** for every view, using mock data.
8. **Unit tests** for: DailyTotal aggregation logic, unit conversion (fl oz ↔ ml), heatmap color tier calculation, goal percentage calculations.

---

## 13. Build Order (Suggested Phases)

Build and verify each phase before moving to the next.

**Phase 1 — Core Data + Models**
- Set up Core Data stack with `LogEntry`
- Implement `TrackerType` registry with defaults
- Implement `TodayViewModel` with daily total aggregation
- Unit test all calculation logic

**Phase 2 — Main Screen**
- `TrackerWheelView` with all three visual layers (pie, ring, bar)
- Static layout for 1, 2, 3, 4 trackers
- Wheel fill animations

**Phase 3 — Entry**
- Custom numeric keypad
- Quick-add preset row
- Today's log sheet (edit/delete)
- Tracker toggle (segmented control for 2+ trackers)

**Phase 4 — Settings**
- All settings sections
- Color pickers wired to theme
- Appearance mode (light/dark/system)
- Custom tracker creation

**Phase 5 — History**
- Heatmap color calculation
- Weekly view with swipe navigation
- Monthly view with swipe navigation
- List view

**Phase 6 — Polish**
- Accessibility labels
- All animations
- Edge cases (first launch, empty state, goal = 0, intake > 2× goal)
- Widget stub + app group

---

## 14. Open Questions / Decisions for Claude Code

Before starting, confirm or decide:
- [ ] Exact default color palette for protein (pie/ring/bar) and water (pie/ring/bar) — choose something genuinely polished
- [ ] Whether `TrackerWheelView` uses SwiftUI `Canvas` or `ZStack` of `Path` layers (Canvas preferred for performance)
- [ ] Whether the custom keypad is a sheet, an inline view, or a `inputView` overlay
- [ ] Exact SF Symbol choices for all icons

Document all decisions made in a `DECISIONS.md` file in the repo root.
