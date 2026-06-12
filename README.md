# NutriTrack

A minimalist iOS app for tracking daily nutrition and hydration goals. Fast, polished, and built for one-handed daily use.

## Features

- **Tracker wheels** — animated pie + ring + overflow-bar visualization for each nutrient
- **Dual thresholds** — minimum goal and main goal per tracker, shown as distinct fill layers
- **Flexible tracker types** — protein and water built in; add custom trackers (fiber, calories, etc.) with no code changes
- **Quick-add presets** — one-tap logging for common amounts (e.g. "Water bottle – 16 fl oz")
- **Streak counter** — optional minimalist streak on the main screen; count days tracked, minimum goals hit, or main goals hit (off by default)
- **Today's log** — view, edit, and delete individual entries for the current day (no history UI — past days are never displayed)
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
├── Models/              TrackerType, QuickAddPreset, StreakMode, LogEntry (Core Data)
├── ViewModels/          TodayViewModel, StreakViewModel, SettingsViewModel
├── Views/
│   ├── Main/            Main screen, tracker wheel, entry area, keypad, log sheet
│   └── Settings/        Tracker config, color pickers, preset editor
├── Theme/               ThemeColors, Color(hex:) extension, Typography
├── Utilities/           DateHelpers, StreakCalculator, UnitConversion (fl oz ↔ ml)
└── Resources/           Assets.xcassets
NutriTrackTests/         41 unit tests (aggregation, unit conversion, streak calculation)
NutriTrackWidget/        WidgetKit stub + WIDGET_TODO.md
```

---

## Architecture Highlights

- **Tracker-generic** — every view iterates over an array of `TrackerType`; adding a new tracker requires only adding it to the registry and running a Core Data migration.
- **AppStorage + Core Data split** — settings and goals live in `UserDefaults` (JSON-encoded); log history lives in Core Data.
- **Canvas rendering** — `TrackerWheelView` uses SwiftUI `Canvas` for a single draw pass (pie, ring, overflow bar) with smooth 350ms easeInOut fill animations.
- **No hardcoded colors** — all tracker colors are hex strings stored in settings, resolved at render time via a `ThemeColors` environment object.
- **Streak, not history** — there is no history UI; the optional streak counter is always computed on the fly from `LogEntry` data (never stored), so changing streak mode or goals yields a correct number.
- **Swift 6 concurrency** — ViewModels are `@MainActor`; Core Data fetches use `async/await`.
- **Inline keypad** — always visible, no sheet dismissal required; supports one-handed use.

### Default Color Palette

| Tracker | Pie | Ring | Bar |
|---|---|---|---|
| Protein | `#E8601C` | `#F4A261` | `#E76F51` |
| Water | `#48CAE4` | `#0096C7` | `#023E8A` |

### Streak Modes

| Mode | A day counts when… |
|---|---|
| Off (default) | — no streak shown |
| Days Tracked | at least one entry was logged |
| Minimum Goals | every active tracker reached its minimum goal |
| Main Goals | every active tracker reached its main goal |

---

## Key Decisions

See [DECISIONS.md](DECISIONS.md) for a full table of architectural choices and their rationale.

---

## Widget

The WidgetKit extension target is stubbed with an App Group entitlement (`group.com.fredericbahnson.nutritrack`) so the Core Data store can be shared with a future widget. See [NutriTrackWidget/WIDGET_TODO.md](NutriTrackWidget/WIDGET_TODO.md) for what remains to be implemented.

---

## Signing

Before running on a physical device, set your development team in **Xcode → NutriTrack target → Signing & Capabilities**. The bundle ID is `com.nutritrack.app` — update it if needed.
