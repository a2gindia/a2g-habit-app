import XCTest
@testable import EconomyKit

final class MetricsTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }
    private func at(_ day: Int, _ h: Int = 9) -> Date {
        utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                      year: 2026, month: 8, day: day, hour: h))!
    }
    private func rec(_ day: Int, variant: FramingVariant = .gain,
                     deepWork: Int = 0, slips: Int = 0, mood: Int? = nil) -> DayRecord {
        DayRecord(logicalDate: at(day), variant: variant, perMinuteRate: 100,
                  potentialZMinutes: 240, grossEarnedMinutes: deepWork, streakMultiplier: 1.0,
                  honestyBonusMinutes: slips * 5, slipMinutes: slips * 30, deepWorkMinutes: deepWork,
                  slipCount: slips, keptAmount: 0, slippedAmount: 0, mood: mood)
    }

    func testEngagementAndGap() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        // days 1,4,5 active; 2,3 empty (missing) → one 2-day gap
        let records = [
            rec(1, variant: .gain, deepWork: 60, mood: 4),
            rec(4, variant: .loss, slips: 2, mood: 2),
            rec(5, variant: .loss, deepWork: 30),
        ]
        let s = Metrics.summarize(records: records, from: at(1), to: at(5), boundary: b)

        XCTAssertEqual(s.daysElapsed, 5)
        XCTAssertEqual(s.daysLogged, 3)
        XCTAssertEqual(s.engagementRate, 0.6, accuracy: 1e-9)

        XCTAssertEqual(s.totalSlips, 2)
        XCTAssertEqual(s.avgSlipsPerLoggedDay, 2.0 / 3.0, accuracy: 1e-9)
        XCTAssertEqual(s.totalDeepWorkMinutes, 90)
        XCTAssertEqual(s.avgDeepWorkMinutesPerLoggedDay, 30, accuracy: 1e-9)

        XCTAssertEqual(s.avgMood, 3.0)   // (4 + 2) / 2
        XCTAssertEqual(s.gainDays, 1)
        XCTAssertEqual(s.lossDays, 2)

        XCTAssertEqual(s.abandonmentGaps.count, 1)
        XCTAssertEqual(s.abandonmentGaps.first?.days, 2)
        XCTAssertEqual(s.abandonmentGaps.first?.start, b.logicalDayStart(for: at(2)))
        XCTAssertEqual(s.abandonmentGaps.first?.end, b.logicalDayStart(for: at(3)))
    }

    func testNoMoodYieldsNilAverage() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let s = Metrics.summarize(records: [rec(1, deepWork: 30)], from: at(1), to: at(1), boundary: b)
        XCTAssertNil(s.avgMood)
    }

    func testSingleInactiveDayIsNotAGap() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        // active on 1 and 3, only day 2 empty → gap length 1, below the ≥2 threshold
        let s = Metrics.summarize(records: [rec(1, deepWork: 10), rec(3, deepWork: 10)],
                                  from: at(1), to: at(3), boundary: b)
        XCTAssertTrue(s.abandonmentGaps.isEmpty)
    }

    func testEmptyHistory() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let s = Metrics.summarize(records: [], from: at(1), to: at(3), boundary: b)
        XCTAssertEqual(s.daysElapsed, 3)
        XCTAssertEqual(s.daysLogged, 0)
        XCTAssertEqual(s.engagementRate, 0)
        XCTAssertEqual(s.abandonmentGaps.first?.days, 3)  // whole window is one gap
    }
}
