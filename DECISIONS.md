# NutriTrack — Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Project generation | XcodeGen 2.44.1 | Reproducible, text-based `.xcodeproj` config; no binary blob in repo |
| TrackerWheelView rendering | SwiftUI `Canvas` API | Single draw pass; better performance than ZStack of Path layers |
| Keypad placement | Inline, always visible in entry area | No modal overhead; supports one-handed use without sheet dismissal |
| Protein colors | pie `#E8601C`, ring `#F4A261`, bar `#E76F51` | Warm terra-cotta / burnt orange palette; accessible on both light and dark |
| Water colors | pie `#48CAE4`, ring `#0096C7`, bar `#023E8A` | Ocean gradient from sky to deep blue; high contrast in both modes |
| History UI | Removed entirely (heatmaps, bar graph, list view) | Stripped-down design: past days are never displayed; only the streak counter reflects them |
| Streak modes | `off` (default), `daysTracked`, `minimumGoals`, `mainGoals` — goal modes require **all** active trackers to hit the threshold | Matches the dual-threshold goal system; default off keeps the app pressure-free |
| Streak storage | Never stored — computed from `LogEntry` on demand (`StreakCalculator` pure logic + `StreakViewModel` background fetch) | No counter state to corrupt; switching mode/goals/trackers always yields a correct number |
| Streak semantics | Consecutive qualifying days ending today; unqualified today doesn't break the streak (day isn't over); empty days never qualify even with 0 goals | Standard streak UX (Duolingo-style); avoids infinite streaks on degenerate 0-goal configs |
| Streak display | Bare number (SF Rounded, secondary color) in bottom-right action-bar slot; hidden when off, invisible placeholder keeps Log pill centered | "Very minimalist — just a number" per product direction |
| Bundle ID | `com.nutritrack.app` | Placeholder — update in Xcode Signing & Capabilities before distribution |
| SF Symbols used | gear=`gearshape.fill`, log=`clock.arrow.circlepath`, add=`plus.circle.fill`, delete=`trash`, backspace=`delete.left.fill` | All available on iOS 17 |
| Swift concurrency | `@MainActor` on ViewModels, async/await Core Data fetches | Swift 6 strict concurrency compliance; all UI updates on main actor |
| Core Data access | Via ViewModels only, never from Views | Separation of concerns; testability |
| AppStorage format | JSON-encoded `[TrackerType]` for configs, JSON-encoded `[QuickAddPreset]` for presets | Codable round-trip; avoids migration for settings changes |
| Water unit storage | Canonical unit stored in Core Data (fl oz), conversion at display time | Avoids data corruption when user switches units |
| Day boundary | Midnight local time (`Calendar.current.startOfDay`) | Matches user expectation; `dayResetHour=0` kept as AppStorage for future |
| Animation duration | 350ms easeInOut | Under 400ms limit; feels responsive without being jarring |
| Color resolution | `Color(hex:)` extension on `Color`; all tracker colors stored as hex strings | Codable, AppStorage-compatible, resolved at render time via ThemeColors |
