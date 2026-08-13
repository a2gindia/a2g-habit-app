import EconomyKit
import Foundation

// Dev-only verification harness — mirrors the load-bearing assertions in the
// XCTest suite so EconomyKit's math can be checked without Xcode installed.
// Run: `swift run verify`. Exits non-zero on any failure.

var failures: [String] = []

@MainActor
func check(_ condition: Bool, _ label: String) {
    if condition {
        print("  ok  \(label)")
    } else {
        print("FAIL  \(label)")
        failures.append(label)
    }
}

func rounded(_ value: Decimal, scale: Int16 = 0) -> NSDecimalNumber {
    NSDecimalNumber(decimal: value).rounding(
        accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .plain, scale: scale,
            raiseOnExactness: false, raiseOnOverflow: false,
            raiseOnUnderflow: false, raiseOnDivideByZero: false))
}

let target: Decimal = 1_000_000_000

print("TimeValueEngine — totalHours matches spec examples")
check(TimeValueEngine.totalHours(for:
    GoalParameters(targetAmount: target, horizonYears: 5, denominator: .calendarHours)) == 43_800,
    "calendar 5y = 43,800 h")
check(TimeValueEngine.totalHours(for:
    GoalParameters(targetAmount: target, horizonYears: 5,
                   denominator: .workingHours(perDay: 8, daysPerWeek: 5))) == 10_400,
    "working 8h×5d×5y = 10,400 h")

print("TimeValueEngine — custom ignores horizon")
let cA = TimeValueEngine.totalHours(for: GoalParameters(targetAmount: target, horizonYears: 1, denominator: .custom(totalHours: 1_000)))
let cB = TimeValueEngine.totalHours(for: GoalParameters(targetAmount: target, horizonYears: 99, denominator: .custom(totalHours: 1_000)))
check(cA == 1_000 && cB == 1_000, "custom total identical across horizons 1 vs 99")

print("TimeValueEngine — rates round to spec headlines")
if let r = TimeValueEngine.rates(for: GoalParameters(targetAmount: target, horizonYears: 5, denominator: .calendarHours)) {
    check(rounded(r.perHour) == NSDecimalNumber(value: 22_831), "calendar perHour ≈ ₹22,831")
    check(r.perMinute == r.perHour / 60, "perMinute = perHour / 60")
    check(r.perSecond == r.perHour / 3600, "perSecond = perHour / 3600")
} else {
    check(false, "calendar rates present")
}
if let r = TimeValueEngine.rates(for: GoalParameters(targetAmount: target, horizonYears: 5,
                                                     denominator: .workingHours(perDay: 8, daysPerWeek: 5))) {
    check(rounded(r.perHour) == NSDecimalNumber(value: 96_154), "working perHour ≈ ₹96,154")
} else {
    check(false, "working rates present")
}

print("TimeValueEngine — invalid inputs are nil, never divide-by-zero")
check(TimeValueEngine.rates(for: GoalParameters(targetAmount: 0, horizonYears: 5, denominator: .calendarHours)) == nil,
    "zero target → nil")
check(TimeValueEngine.totalHours(for: GoalParameters(targetAmount: target, horizonYears: 0, denominator: .calendarHours)) == nil,
    "zero horizon → nil")
check(TimeValueEngine.rates(for: GoalParameters(targetAmount: target, horizonYears: 5, denominator: .custom(totalHours: 0))) == nil,
    "custom 0 hours → nil")
check(TimeValueEngine.totalHours(for: GoalParameters(targetAmount: target, horizonYears: 5,
                                                     denominator: .workingHours(perDay: 8, daysPerWeek: 0))) == nil,
    "working 0 days → nil")

print("MoneyFormatting — Indian grouping and rounding")
check(MoneyFormatting.inr(2_283_105) == "₹22,83,105", "Indian grouping ₹22,83,105")
check(MoneyFormatting.inr(Decimal(string: "22831.05")!) == "₹22,831", "rounds 22831.05 → ₹22,831")
check(MoneyFormatting.rate(Decimal(string: "6.341")!, per: .second) == "₹6.34/s", "per-second 2 digits ₹6.34/s")
check(MoneyFormatting.rate(22_831, per: .hour) == "₹22,831/h", "per-hour suffix ₹22,831/h")

// MARK: Scoring engine ------------------------------------------------------

let rate: Decimal = 100   // ₹100/min
let Z = 240               // potential 240 min → ₹24,000

func deepWork() -> ScoringHabit { ScoringHabit(id: "dw", kind: .build, usesLoggedDuration: true) }
func cig(cost: Int = 30) -> ScoringHabit { ScoringHabit(id: "cig", kind: .breakHabit, costMinutes: cost) }
func flat(reward: Int, target: Int?) -> ScoringHabit {
    ScoringHabit(id: "b", kind: .build, rewardMinutes: reward, targetPerDay: target)
}

print("ScoringEngine — floor at zero")
let floored = ScoringEngine.score(
    habits: [deepWork(), cig(cost: 200)],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 60),
           ScoringLog(habitID: "cig"), ScoringLog(habitID: "cig")],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(floored.keptAmount == 0, "heavy-slip day floors kept to ₹0")
check(floored.slippedAmount >= 0 && floored.keptAmount >= 0, "no negative amounts")

print("ScoringEngine — honesty softens but never erases the sting")
let withSlip = ScoringEngine.score(
    habits: [deepWork(), cig(cost: 30)],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 120), ScoringLog(habitID: "cig")],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
let noSlip = ScoringEngine.score(
    habits: [deepWork(), cig(cost: 30)],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 120)],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(noSlip.keptAmount - withSlip.keptAmount == Decimal(25) * rate, "slip nets −(30−5)=25 min → ₹2,500")
check(withSlip.keptAmount < noSlip.keptAmount, "logged slip still stings")

print("ScoringEngine — farming guard")
let farmNil = ScoringEngine.score(habits: [flat(reward: 30, target: nil)],
    logs: Array(repeating: ScoringLog(habitID: "b"), count: 5),
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(farmNil.grossEarnedMinutes == 30, "flat build capped once/day (nil target)")
let farmTarget = ScoringEngine.score(habits: [flat(reward: 10, target: 3)],
    logs: Array(repeating: ScoringLog(habitID: "b"), count: 5),
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(farmTarget.grossEarnedMinutes == 30, "flat build honours targetPerDay=3 → 3×10")

print("ScoringEngine — streak multiplies earnings only, capped")
let streaked = ScoringEngine.score(
    habits: [deepWork(), cig(cost: 30)],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 100), ScoringLog(habitID: "cig")],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.5)
check(streaked.keptAmount == Decimal(125) * rate, "100×1.5 +5 −30 = 125 min → ₹12,500")
let capped = ScoringEngine.score(habits: [deepWork()],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 100)],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 9.0)
check(capped.streakMultiplier == 1.5, "streak multiplier clamped to 1.5")

print("ScoringEngine — kept/slipped vs potential")
let below = ScoringEngine.score(habits: [deepWork()],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 100)],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(below.keptAmount + below.slippedAmount == below.potentialAmount, "kept+slipped = potential (below ceiling)")
let over = ScoringEngine.score(habits: [deepWork()],
    logs: [ScoringLog(habitID: "dw", durationMinutes: 400)],
    perMinuteRate: rate, potentialZMinutes: Z, streakMultiplier: 1.0)
check(over.slippedAmount == 0 && over.keptAmount > over.potentialAmount, "overachieving clamps slipped to ₹0")

// MARK: DayBoundary ----------------------------------------------------------

var utc = Calendar(identifier: .gregorian)
utc.timeZone = TimeZone(identifier: "UTC")!
@MainActor
func d(_ day: Int, _ h: Int, _ mi: Int = 0) -> Date {
    utc.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                  year: 2026, month: 8, day: day, hour: h, minute: mi))!
}
let boundary = DayBoundary(lightsOutHour: 3, calendar: utc)
print("DayBoundary — lights-out rollover")
check(boundary.logicalDayStart(for: d(15, 1)) == d(14, 3), "1am → previous logical day (3am start)")
check(boundary.logicalDayStart(for: d(15, 9)) == d(15, 3), "9am → same logical day")
check(boundary.sameLogicalDay(d(15, 23, 30), d(16, 2)), "11:30pm & 2am share a logical day")

// MARK: StreakCalculator -----------------------------------------------------

print("StreakCalculator — curve and counting")
check(StreakCalculator.multiplier(streakDays: 1) == 1.0, "streak 1 → 1.0×")
check(abs(StreakCalculator.multiplier(streakDays: 6) - 1.5) < 1e-9, "streak 6 → 1.5×")
check(StreakCalculator.multiplier(streakDays: 50) == 1.5, "streak 50 → capped 1.5×")
let loggedDays = Set([d(12, 9), d(13, 9), d(14, 9)].map { boundary.logicalDayStart(for: $0) })
check(StreakCalculator.currentStreak(loggedDayStarts: loggedDays, asOf: d(14, 9), boundary: boundary) == 3,
      "three consecutive logged days → streak 3")
let gapped = Set([d(11, 9), d(12, 9), d(14, 9)].map { boundary.logicalDayStart(for: $0) })
check(StreakCalculator.currentStreak(loggedDayStarts: gapped, asOf: d(14, 9), boundary: boundary) == 1,
      "gap breaks the streak")

// MARK: Framing --------------------------------------------------------------

print("FramingPresenter — same math, different lens")
let fk: Decimal = 18_400, fs: Decimal = 5_600, fp: Decimal = 24_000
let gain = FramingPresenter.headline(kept: fk, slipped: fs, potential: fp, variant: .gain)
let loss = FramingPresenter.headline(kept: fk, slipped: fs, potential: fp, variant: .loss)
check(gain.amount == fk, "gain primary = kept")
check(loss.amount == fs, "loss primary = slipped")
check(gain.amount + loss.amount == fp, "both primaries reconstruct the potential (identical math)")
check(gain.headline == "Kept ₹18,400 toward your goal today.", "gain copy")
check(loss.headline == "You let ₹5,600 slip today.", "loss copy")

print("FramingRotation — alternate weekly, honouring lights-out")
check(FramingRotation.variant(for: d(1, 9), anchor: d(1, 9), boundary: boundary) == .gain, "week 0 → gain")
check(FramingRotation.variant(for: d(8, 9), anchor: d(1, 9), boundary: boundary) == .loss, "week 1 → loss")
check(FramingRotation.variant(for: d(15, 9), anchor: d(1, 9), boundary: boundary) == .gain, "week 2 → gain")
check(FramingRotation.variant(for: d(8, 2), anchor: d(1, 9), boundary: boundary) == .gain, "2am day 8 still week 0 (lights-out)")

// MARK: Metrics + Export -----------------------------------------------------

@MainActor
func record(_ day: Int, variant: FramingVariant = .gain, deepWork: Int = 0,
            slips: Int = 0, mood: Int? = nil) -> DayRecord {
    DayRecord(logicalDate: d(day, 9), variant: variant, perMinuteRate: 100,
              potentialZMinutes: 240, grossEarnedMinutes: deepWork, streakMultiplier: 1.0,
              honestyBonusMinutes: slips * 5, slipMinutes: slips * 30, deepWorkMinutes: deepWork,
              slipCount: slips, keptAmount: 0, slippedAmount: 0, mood: mood)
}

print("Metrics — engagement, averages, abandonment gaps")
let history = [record(1, variant: .gain, deepWork: 60, mood: 4),
               record(4, variant: .loss, slips: 2, mood: 2),
               record(5, variant: .loss, deepWork: 30)]
let summary = Metrics.summarize(records: history, from: d(1, 9), to: d(5, 9), boundary: boundary)
check(summary.daysElapsed == 5 && summary.daysLogged == 3, "3 logged of 5 elapsed")
check(abs(summary.engagementRate - 0.6) < 1e-9, "engagement rate 0.6")
check(summary.totalSlips == 2 && summary.totalDeepWorkMinutes == 90, "slip & deep-work totals")
check(summary.avgMood == 3.0, "avg mood (4,2) = 3.0")
check(summary.gainDays == 1 && summary.lossDays == 2, "variant day counts")
check(summary.abandonmentGaps.count == 1 && summary.abandonmentGaps.first?.days == 2, "one 2-day gap (days 2–3)")

print("Exporter — CSV and JSON")
let csv = Exporter.csv(history)
let csvLines = csv.split(separator: "\n", omittingEmptySubsequences: false)
check(csvLines.count == history.count + 1, "CSV header + one row per record")
check(csvLines[0].hasPrefix("logicalDate,variant,"), "CSV header row")
if let json = try? Exporter.json(history) {
    let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
    let back = (try? decoder.decode([DayRecord].self, from: Data(json.utf8))) ?? []
    check(back == history.sorted { $0.logicalDate < $1.logicalDate }, "JSON round-trips to identical records")
} else {
    check(false, "JSON encodes")
}

print(String(repeating: "─", count: 40))
if failures.isEmpty {
    print("All checks passed ✓")
} else {
    print("\(failures.count) FAILED:")
    failures.forEach { print("  • \($0)") }
    exit(1)
}
