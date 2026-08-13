import XCTest
@testable import EconomyKit

final class DayBoundaryTests: XCTestCase {

    // Fixed UTC calendar so results are deterministic regardless of host TZ.
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> Date {
        utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                      year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testBeforeLightsOutBelongsToPreviousDay() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        // 1am on the 15th, lights-out 3am → logical day started 3am on the 14th
        XCTAssertEqual(b.logicalDayStart(for: date(2026, 8, 15, 1)),
                       date(2026, 8, 14, 3))
    }

    func testAfterLightsOutBelongsToSameDay() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        XCTAssertEqual(b.logicalDayStart(for: date(2026, 8, 15, 9)),
                       date(2026, 8, 15, 3))
    }

    func testExactlyLightsOutIsStartOfNewDay() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        XCTAssertEqual(b.logicalDayStart(for: date(2026, 8, 15, 3)),
                       date(2026, 8, 15, 3))
    }

    func testLateNightAndNextMorningShareLogicalDay() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        // 11:30pm on the 15th and 2am on the 16th are the same logical day
        XCTAssertTrue(b.sameLogicalDay(date(2026, 8, 15, 23, 30), date(2026, 8, 16, 2)))
    }

    func testMidnightLightsOutEqualsCalendarDay() {
        let b = DayBoundary(lightsOutHour: 0, calendar: utc)
        XCTAssertEqual(b.logicalDayStart(for: date(2026, 8, 15, 1)),
                       date(2026, 8, 15, 0))
    }
}
