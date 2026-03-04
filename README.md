# NutriTrack

A minimalist iOS app for tracking daily nutrition and hydration goals. Fast, polished, and built for one-handed daily use.

## Features

- **Tracker wheels** — animated pie + ring + overflow-bar visualization for each nutrient
- **Dual thresholds** — minimum goal and main goal per tracker, shown as distinct fill layers
- **Flexible tracker types** — protein and water built in; add custom trackers (fiber, calories, etc.) with no code changes
- **Quick-add presets** — one-tap logging for common amounts (e.g. "Water bottle – 16 fl oz")
- **History heatmap** — weekly and monthly views with color-coded intensity tiers
- **Today's log** — view, edit, and delete individual entries for the current day
- **Dark mode** — full light/dark support; appearance can be forced or follow system
- **Widget stub** — WidgetKit extension with App Group entitlement, ready to implement

---

## Requirements

| Requirement | Version |
|---|---|
| iOS | 17.0+ |
| Xcode | 15+ |
| XcodeGen | 2.44.1+ |
| Swift | 5.9+ |

No third-party dependencies — Apple SDK only.

---

## How to Build

### 1. Install XcodeGen (if not already installed)

```bash
brew install xcodegen
```

### 2. Clone the repo

```bash
git clone https://github.com/fredericbahnson/nutritracker.git
cd nutritracker
```

### 3. Generate the Xcode project

```bash
xcodegen generate
```

> The generated `NutriTrack.xcodeproj` is also committed to the repo, so you can skip this step if you just cloned and the project file is already present.

### 4. Open in Xcode

```bash
open NutriTrack.xcodeproj
```

### 5. Select a simulator and run

Choose **iPhone 17** (or any iPhone running iOS 17+) from the scheme picker and press ⌘R.

### Running Tests

```bash
xcodebuild test \
  -scheme NutriTrack \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0.1' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

---

## Project Structure

```
NutriTrack/
├── App/                 App entry point, Core Data stack
├── Models/              TrackerType, QuickAddPreset, LogEntry (Core Data)
├── ViewModels/          TodayViewModel, HistoryViewModel, SettingsViewModel
├── Views/
│   ├── Main/            Main screen, tracker wheel, entry area, keypad, log sheet
│   ├── History/         Heatmap (weekly + monthly), list view
│   └── Settings/        Tracker config, color pickers, preset editor
├── Theme/               ThemeColors, Color(hex:) extension, Typography
├── Utilities/           DateHelpers, UnitConversion (fl oz ↔ ml)
└── Resources/           Assets.xcassets
NutriTrackTests/         21 unit tests (aggregation, unit conversion, heatmap tiers)
NutriTrackWidget/        WidgetKit stub + WIDGET_TODO.md
```

---

## Architecture Highlights

- **Tracker-generic** — every view iterates over an array of `TrackerType`; adding a new tracker requires only adding it to the registry and running a Core Data migration.
- **AppStorage + Core Data split** — settings and goals live in `UserDefaults` (JSON-encoded); log history lives in Core Data.
- **Canvas rendering** — `TrackerWheelView` uses SwiftUI `Canvas` for a single draw pass (pie, ring, overflow bar) with smooth 350ms easeInOut fill animations.
- **No hardcoded colors** — all tracker and heatmap colors are hex strings stored in settings, resolved at render time via a `ThemeColors` environment object.
- **Swift 6 concurrency** — ViewModels are `@MainActor`; Core Data fetches use `async/await`.
- **Inline keypad** — always visible, no sheet dismissal required; supports one-handed use.

### Default Color Palette

| Tracker | Pie | Ring | Bar |
|---|---|---|---|
| Protein | `#E8601C` | `#F4A261` | `#E76F51` |
| Water | `#48CAE4` | `#0096C7` | `#023E8A` |

### Heatmap Tiers

| Intake range | Color |
|---|---|
| 0 | Empty |
| 0 – minimum goal | Green `#4CAF50` (opacity scales with progress) |
| minimum – main goal | Blue `#2196F3` (opacity scales with progress) |
| > main goal | Purple `#9C27B0` (opacity scales, capped at 2× goal) |

---

## Key Decisions

See [DECISIONS.md](DECISIONS.md) for a full table of architectural choices and their rationale.

---

## Widget

The WidgetKit extension target is stubbed with an App Group entitlement (`group.com.fredericbahnson.nutritrack`) so the Core Data store can be shared with a future widget. See [NutriTrackWidget/WIDGET_TODO.md](NutriTrackWidget/WIDGET_TODO.md) for what remains to be implemented.

---

## Signing

Before running on a physical device, set your development team in **Xcode → NutriTrack target → Signing & Capabilities**. The bundle ID is `com.nutritrack.app` — update it if needed.
