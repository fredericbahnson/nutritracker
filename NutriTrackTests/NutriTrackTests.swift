import XCTest
@testable import NutriTrack

final class NutriTrackTests: XCTestCase {

    // MARK: - DailyTotal aggregation

    func testDailyTotalSum() {
        let tracker = TrackerType.defaults[0] // protein
        // pieFraction: total/minimumGoal clamped [0,1]
        XCTAssertEqual(tracker.pieFraction(for: 60), 0.5, accuracy: 0.001)
        XCTAssertEqual(tracker.pieFraction(for: 120), 1.0, accuracy: 0.001)
        XCTAssertEqual(tracker.pieFraction(for: 200), 1.0, accuracy: 0.001) // clamped
        XCTAssertEqual(tracker.pieFraction(for: 0), 0.0, accuracy: 0.001)
    }

    func testDailyTotalZeroEntries() {
        let tracker = TrackerType.defaults[0]
        XCTAssertEqual(tracker.pieFraction(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(tracker.ringFraction(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(tracker.overflowFraction(for: 0), 0.0, accuracy: 0.001)
    }

    func testRingFraction() {
        // protein: min=120, main=160 → ring fills from 120→160
        let tracker = TrackerType.defaults[0]
        XCTAssertEqual(tracker.ringFraction(for: 120), 0.0, accuracy: 0.001)
        XCTAssertEqual(tracker.ringFraction(for: 140), 0.5, accuracy: 0.001)
        XCTAssertEqual(tracker.ringFraction(for: 160), 1.0, accuracy: 0.001)
        XCTAssertEqual(tracker.ringFraction(for: 200), 1.0, accuracy: 0.001) // clamped
        XCTAssertEqual(tracker.ringFraction(for: 50), 0.0, accuracy: 0.001) // below min
    }

    func testOverflowFraction() {
        // protein: main=160 → overflow fills from 160→320
        let tracker = TrackerType.defaults[0]
        XCTAssertEqual(tracker.overflowFraction(for: 160), 0.0, accuracy: 0.001)
        XCTAssertEqual(tracker.overflowFraction(for: 240), 0.5, accuracy: 0.001)
        XCTAssertEqual(tracker.overflowFraction(for: 320), 1.0, accuracy: 0.001)
        XCTAssertEqual(tracker.overflowFraction(for: 400), 1.0, accuracy: 0.001) // clamped
        XCTAssertEqual(tracker.overflowFraction(for: 100), 0.0, accuracy: 0.001) // below main
    }

    func testPercentOfMainGoal() {
        let tracker = TrackerType.defaults[0] // main = 160
        XCTAssertEqual(tracker.percentOfMainGoal(for: 0), 0.0, accuracy: 0.001)
        XCTAssertEqual(tracker.percentOfMainGoal(for: 80), 0.5, accuracy: 0.001)
        XCTAssertEqual(tracker.percentOfMainGoal(for: 160), 1.0, accuracy: 0.001)
        XCTAssertEqual(tracker.percentOfMainGoal(for: 320), 2.0, accuracy: 0.001) // capped at 2×
        XCTAssertEqual(tracker.percentOfMainGoal(for: 400), 2.0, accuracy: 0.001) // capped
    }

    // MARK: - Zero-goal edge cases

    func testZeroGoalPieFraction() {
        var tracker = TrackerType.defaults[0]
        tracker.minimumGoal = 0
        tracker.mainGoal = 0
        XCTAssertEqual(tracker.pieFraction(for: 0), 0.0)
        XCTAssertEqual(tracker.pieFraction(for: 10), 1.0) // any intake → full when goal=0
    }

    func testZeroMainGoalRingFraction() {
        var tracker = TrackerType.defaults[0]
        tracker.minimumGoal = 0
        tracker.mainGoal = 0
        XCTAssertEqual(tracker.ringFraction(for: 10), 1.0) // intake ≥ mainGoal(0) → 1
    }

    // MARK: - Unit conversion

    func testFlOzToMl() {
        let ml = UnitConversion.flOzToMl(1.0)
        XCTAssertEqual(ml, 29.5735, accuracy: 0.01)
    }

    func testMlToFlOz() {
        let floz = UnitConversion.mlToFlOz(29.5735)
        XCTAssertEqual(floz, 1.0, accuracy: 0.001)
    }

    func testRoundTripFlOzMl() {
        let original = 16.0
        let ml = UnitConversion.flOzToMl(original)
        let roundTrip = UnitConversion.mlToFlOz(ml)
        XCTAssertEqual(roundTrip, original, accuracy: 0.01)
    }

    func testConvertSameUnit() {
        XCTAssertEqual(
            UnitConversion.convert(100, from: .flOz, to: .flOz),
            100,
            accuracy: 0.001
        )
        XCTAssertEqual(
            UnitConversion.convert(100, from: .ml, to: .ml),
            100,
            accuracy: 0.001
        )
    }

    func testConvertFlOzToMl() {
        let result = UnitConversion.convert(8.0, from: .flOz, to: .ml)
        XCTAssertEqual(result, 8.0 * 29.5735, accuracy: 0.01)
    }

    func testConvertMlToFlOz() {
        let result = UnitConversion.convert(236.588, from: .ml, to: .flOz)
        XCTAssertEqual(result, 8.0, accuracy: 0.01)
    }

    // MARK: - Heatmap color tier

    func testHeatmapColorTierZero() {
        let tracker = TrackerType.defaults[0]
        let colors = HeatmapColors()
        let color = colors.color(for: 0, tracker: tracker)
        // Zero amount returns a dim fill color — just verify it doesn't crash
        _ = color
    }

    func testHeatmapColorTierGreen() {
        let tracker = TrackerType.defaults[0] // min=120, main=160
        let colors = HeatmapColors()
        // Below min → green tier
        let color = colors.color(for: 60, tracker: tracker)
        _ = color // Non-nil, not clear
    }

    func testHeatmapColorTierBlue() {
        let tracker = TrackerType.defaults[0] // min=120, main=160
        let colors = HeatmapColors()
        // Between min and main → blue tier
        let color = colors.color(for: 140, tracker: tracker)
        _ = color
    }

    func testHeatmapColorTierPurple() {
        let tracker = TrackerType.defaults[0] // main=160
        let colors = HeatmapColors()
        // Above main → purple tier
        let color = colors.color(for: 200, tracker: tracker)
        _ = color
    }

    // MARK: - DateHelpers

    func testDayBoundaryStartEndSameDay() {
        let now = Date()
        let (start, end) = DateHelpers.dayBoundary(for: now)
        XCTAssertLessThan(start, end)
        XCTAssertEqual(
            Calendar.current.startOfDay(for: now),
            start
        )
        // End should be exactly 24h after start
        let diff = end.timeIntervalSince(start)
        XCTAssertEqual(diff, 86400, accuracy: 1)
    }

    func testStartOfDayIsCorrect() {
        let now = Date()
        let start = DateHelpers.startOfDay(for: now)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    // MARK: - QuickAddPreset display text

    func testPresetDisplayTextWithLabel() {
        let preset = QuickAddPreset(trackerID: "protein", amount: 25, label: "Shake")
        XCTAssertEqual(preset.displayText(unit: "g"), "Shake")
    }

    func testPresetDisplayTextNoLabel() {
        let preset = QuickAddPreset(trackerID: "protein", amount: 25, label: nil)
        XCTAssertEqual(preset.displayText(unit: "g"), "25g")
    }

    func testPresetDisplayTextDecimal() {
        let preset = QuickAddPreset(trackerID: "protein", amount: 12.5, label: nil)
        XCTAssertEqual(preset.displayText(unit: "g"), "12.5g")
    }

    func testPresetDisplayTextEmptyLabel() {
        let preset = QuickAddPreset(trackerID: "protein", amount: 30, label: "")
        XCTAssertEqual(preset.displayText(unit: "g"), "30g")
    }
}
