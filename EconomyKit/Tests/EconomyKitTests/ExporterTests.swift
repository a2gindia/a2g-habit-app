import XCTest
@testable import EconomyKit

final class ExporterTests: XCTestCase {

    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
    }
    private func at(_ day: Int) -> Date {
        utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                      year: 2026, month: 8, day: day, hour: 3))!
    }
    private func rec(_ day: Int, variant: FramingVariant, mood: Int?) -> DayRecord {
        DayRecord(logicalDate: at(day), variant: variant, perMinuteRate: Decimal(string: "22831.05")!,
                  potentialZMinutes: 240, grossEarnedMinutes: 100, streakMultiplier: 1.1,
                  honestyBonusMinutes: 5, slipMinutes: 30, deepWorkMinutes: 100,
                  slipCount: 1, keptAmount: 18_400, slippedAmount: 5_600, mood: mood)
    }

    func testCSVHasHeaderAndRowPerRecord() {
        let csv = Exporter.csv([rec(2, variant: .loss, mood: nil), rec(1, variant: .gain, mood: 4)])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertEqual(lines.count, 3) // header + 2 rows
        XCTAssertTrue(lines[0].hasPrefix("logicalDate,variant,"))
        // sorted by date: day 1 first
        XCTAssertTrue(lines[1].contains("gain"))
        XCTAssertTrue(lines[2].contains("loss"))
    }

    func testCSVEmptyMoodCell() {
        let csv = Exporter.csv([rec(1, variant: .loss, mood: nil)])
        // trailing empty field for the missing mood
        XCTAssertTrue(csv.split(separator: "\n").last!.hasSuffix(","))
    }

    func testCSVKeepsFullDecimalPrecision() {
        let csv = Exporter.csv([rec(1, variant: .gain, mood: 4)])
        XCTAssertTrue(csv.contains("22831.05"))
    }

    func testJSONRoundTrips() throws {
        let records = [rec(3, variant: .loss, mood: nil), rec(1, variant: .gain, mood: 4)]
        let json = try Exporter.json(records)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let back = try decoder.decode([DayRecord].self, from: Data(json.utf8))
        XCTAssertEqual(back, records.sorted { $0.logicalDate < $1.logicalDate })
    }
}
