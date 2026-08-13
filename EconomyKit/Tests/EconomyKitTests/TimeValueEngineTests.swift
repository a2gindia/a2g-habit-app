import XCTest
@testable import EconomyKit

final class TimeValueEngineTests: XCTestCase {

    // 100 cr target used across the spec's worked examples.
    private let target: Decimal = 1_000_000_000

    // MARK: totalHours matches the spec's worked examples

    func testCalendarHoursFiveYears() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5, denominator: .calendarHours)
        XCTAssertEqual(TimeValueEngine.totalHours(for: p), 43_800) // 365·24·5
    }

    func testWorkingHoursFiveYears() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5,
                               denominator: .workingHours(perDay: 8, daysPerWeek: 5))
        XCTAssertEqual(TimeValueEngine.totalHours(for: p), 10_400) // 8·5·52·5
    }

    func testCustomIgnoresHorizon() {
        // Same custom pool, wildly different horizons → identical total.
        let a = GoalParameters(targetAmount: target, horizonYears: 1, denominator: .custom(totalHours: 1_000))
        let b = GoalParameters(targetAmount: target, horizonYears: 99, denominator: .custom(totalHours: 1_000))
        XCTAssertEqual(TimeValueEngine.totalHours(for: a), 1_000)
        XCTAssertEqual(TimeValueEngine.totalHours(for: b), 1_000)
    }

    // MARK: rates match the spec's headline numbers (₹22,831/h, ~₹96,000/h)

    func testCalendarPerHourRoundsToSpec() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5, denominator: .calendarHours)
        let rates = try XCTUnwrap(TimeValueEngine.rates(for: p))
        // 1e9 / 43,800 = 22,831.05…
        let roundedPerHour = NSDecimalNumber(decimal: rates.perHour).rounding(accordingToBehavior: halfUp0)
        XCTAssertEqual(roundedPerHour, NSDecimalNumber(value: 22_831))
    }

    func testWorkingPerHourRoundsToSpec() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5,
                               denominator: .workingHours(perDay: 8, daysPerWeek: 5))
        let rates = try XCTUnwrap(TimeValueEngine.rates(for: p))
        // 1e9 / 10,400 = 96,153.8…  spec says "~₹96,000"
        let roundedPerHour = NSDecimalNumber(decimal: rates.perHour).rounding(accordingToBehavior: halfUp0)
        XCTAssertEqual(roundedPerHour, NSDecimalNumber(value: 96_154))
    }

    // MARK: rate relationships are exact

    func testMinuteAndSecondAreExactSubdivisions() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5, denominator: .calendarHours)
        let r = try XCTUnwrap(TimeValueEngine.rates(for: p))
        XCTAssertEqual(r.perMinute, r.perHour / 60)
        XCTAssertEqual(r.perSecond, r.perHour / 3600)
    }

    // MARK: invalid inputs yield nil instead of dividing by zero

    func testZeroTargetIsNil() {
        let p = GoalParameters(targetAmount: 0, horizonYears: 5, denominator: .calendarHours)
        XCTAssertNil(TimeValueEngine.rates(for: p))
    }

    func testZeroHorizonIsNil() {
        let p = GoalParameters(targetAmount: target, horizonYears: 0, denominator: .calendarHours)
        XCTAssertNil(TimeValueEngine.totalHours(for: p))
        XCTAssertNil(TimeValueEngine.rates(for: p))
    }

    func testCustomZeroHoursIsNil() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5, denominator: .custom(totalHours: 0))
        XCTAssertNil(TimeValueEngine.rates(for: p))
    }

    func testWorkingHoursWithZeroDaysIsNil() {
        let p = GoalParameters(targetAmount: target, horizonYears: 5,
                               denominator: .workingHours(perDay: 8, daysPerWeek: 0))
        XCTAssertNil(TimeValueEngine.totalHours(for: p))
    }

    private let halfUp0 = NSDecimalNumberHandler(roundingMode: .plain, scale: 0,
                                                 raiseOnExactness: false, raiseOnOverflow: false,
                                                 raiseOnUnderflow: false, raiseOnDivideByZero: false)
}
