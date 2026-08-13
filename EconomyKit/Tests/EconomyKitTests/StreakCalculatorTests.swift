import XCTest
@testable import EconomyKit

final class StreakCalculatorTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ d: Int, _ h: Int = 9) -> Date {
        utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                      year: 2026, month: 8, day: d, hour: h))!
    }

    // MARK: multiplier curve

    func testMultiplierGrowsThenCaps() {
        XCTAssertEqual(StreakCalculator.multiplier(streakDays: 0), 1.0)
        XCTAssertEqual(StreakCalculator.multiplier(streakDays: 1), 1.0)
        XCTAssertEqual(StreakCalculator.multiplier(streakDays: 2), 1.1, accuracy: 1e-9)
        XCTAssertEqual(StreakCalculator.multiplier(streakDays: 6), 1.5, accuracy: 1e-9)
        XCTAssertEqual(StreakCalculator.multiplier(streakDays: 50), 1.5) // capped
    }

    // MARK: consecutive-day counting

    func testCountsConsecutiveLoggedDays() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let logged = Set([day(12), day(13), day(14)].map { b.logicalDayStart(for: $0) })
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDayStarts: logged, asOf: day(14), boundary: b), 3)
    }

    func testStopsAtGap() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        // gap on the 13th
        let logged = Set([day(11), day(12), day(14)].map { b.logicalDayStart(for: $0) })
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDayStarts: logged, asOf: day(14), boundary: b), 1)
    }

    func testZeroWhenTodayNotLogged() {
        let b = DayBoundary(lightsOutHour: 3, calendar: utc)
        let logged = Set([day(12), day(13)].map { b.logicalDayStart(for: $0) })
        XCTAssertEqual(StreakCalculator.currentStreak(loggedDayStarts: logged, asOf: day(15), boundary: b), 0)
    }
}
