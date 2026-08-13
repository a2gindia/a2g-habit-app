import XCTest
@testable import EconomyKit

final class FramingTests: XCTestCase {

    // MARK: the structural invariant — both framings are the same math

    func testGainPrimaryIsKeptLossPrimaryIsSlipped() {
        let kept: Decimal = 18_400, slipped: Decimal = 5_600, potential: Decimal = 24_000
        let gain = FramingPresenter.headline(kept: kept, slipped: slipped, potential: potential, variant: .gain)
        let loss = FramingPresenter.headline(kept: kept, slipped: slipped, potential: potential, variant: .loss)
        XCTAssertEqual(gain.amount, kept)
        XCTAssertEqual(loss.amount, slipped)
    }

    func testBothFramingsSumToPotential() {
        // The two primary numbers reconstruct the same whole — proving neither
        // variant invents or drops value.
        let kept: Decimal = 18_400, slipped: Decimal = 5_600, potential: Decimal = 24_000
        let gain = FramingPresenter.headline(kept: kept, slipped: slipped, potential: potential, variant: .gain)
        let loss = FramingPresenter.headline(kept: kept, slipped: slipped, potential: potential, variant: .loss)
        XCTAssertEqual(gain.amount + loss.amount, potential)
    }

    func testFramingFlowsFromScoringEngine() {
        // End-to-end: engine output → presenter, invariant holds on real numbers.
        let rate: Decimal = 100
        let result = ScoringEngine.score(
            habits: [ScoringHabit(id: "dw", kind: .build, usesLoggedDuration: true)],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 100)],
            perMinuteRate: rate, potentialZMinutes: 240, streakMultiplier: 1.0)
        for variant in FramingVariant.allCases {
            let h = FramingPresenter.headline(kept: result.keptAmount,
                                              slipped: result.slippedAmount,
                                              potential: result.potentialAmount,
                                              variant: variant)
            XCTAssertFalse(h.headline.isEmpty)
            XCTAssertTrue(h.amountFormatted.contains("₹"))
        }
    }

    func testCopyStrings() {
        let h = FramingPresenter.headline(kept: 18_400, slipped: 5_600, potential: 24_000, variant: .gain)
        XCTAssertEqual(h.headline, "Kept ₹18,400 toward your goal today.")
        XCTAssertEqual(h.caption, "kept toward your goal today")
        let l = FramingPresenter.headline(kept: 18_400, slipped: 5_600, potential: 24_000, variant: .loss)
        XCTAssertEqual(l.headline, "You let ₹5,600 slip today.")
        XCTAssertEqual(l.caption, "let slip today")
    }

    // MARK: weekly rotation

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }
    private func at(_ day: Int, _ h: Int = 9) -> Date {
        utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                      year: 2026, month: 8, day: day, hour: h))!
    }

    func testRotationAlternatesByWeek() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let anchor = at(1)
        XCTAssertEqual(FramingRotation.variant(for: at(1), anchor: anchor, boundary: b), .gain)   // week 0
        XCTAssertEqual(FramingRotation.variant(for: at(7), anchor: anchor, boundary: b), .gain)   // still week 0
        XCTAssertEqual(FramingRotation.variant(for: at(8), anchor: anchor, boundary: b), .loss)   // week 1
        XCTAssertEqual(FramingRotation.variant(for: at(15), anchor: anchor, boundary: b), .gain)  // week 2
    }

    func testRotationRespectsLightsOut() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let anchor = at(1)
        // 2am on day 8 is still logical day 7 → week 0 → .gain, not the new week
        XCTAssertEqual(FramingRotation.variant(for: at(8, 2), anchor: anchor, boundary: b), .gain)
    }

    func testWeekIndexClampsBeforeAnchor() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        XCTAssertEqual(FramingRotation.weekIndex(for: at(1), anchor: at(20), boundary: b), 0)
    }
}
