import XCTest
@testable import EconomyKit

final class MoneyFormattingTests: XCTestCase {

    func testIndianGrouping() {
        // Indian grouping: last three digits, then pairs → 22,83,105 not 2,283,105.
        XCTAssertEqual(MoneyFormatting.inr(2_283_105), "₹22,83,105")
    }

    func testZeroFractionDigitsRoundsHalfUp() {
        XCTAssertEqual(MoneyFormatting.inr(Decimal(string: "22831.05")!), "₹22,831")
        XCTAssertEqual(MoneyFormatting.inr(Decimal(string: "96153.85")!), "₹96,154")
    }

    func testPerSecondShowsTwoDigits() {
        // 1e9 / 43,800 / 3600 ≈ 6.34 /s
        let perSecond = Decimal(string: "6.341")!
        XCTAssertEqual(MoneyFormatting.rate(perSecond, per: .second), "₹6.34/s")
    }

    func testRateSuffixes() {
        XCTAssertEqual(MoneyFormatting.rate(22_831, per: .hour), "₹22,831/h")
        XCTAssertEqual(MoneyFormatting.rate(380, per: .minute), "₹380/min")
    }
}
