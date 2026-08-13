import XCTest
import SwiftData
import EconomyKit
@testable import HabitApp

/// Unit tests for the SwiftData ↔ EconomyKit bridge: correct habit/log joining,
/// today-only filtering, streak inclusion, framing variant, and DayScore
/// persistence with mood preservation. Uses an in-memory store.
@MainActor
final class DayScoreServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    // A fixed "now" at noon so the lights-out (3am) boundary is unambiguous.
    private let cal = Calendar.current
    private var now: Date { cal.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 12))! }
    private func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now)! }

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Goal.self, Habit.self, HabitLog.self, DayScore.self, AppConfig.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    override func tearDown() { container = nil }

    // MARK: fixtures

    @discardableResult
    private func makeGoal() -> Goal {
        let g = Goal(targetAmount: 1_000_000_000, horizonYears: 5, denominator: .calendarHours)
        context.insert(g)
        return g
    }
    private func makeConfig() -> AppConfig {
        // Anchor rotation at `now` so week 0 → .gain deterministically.
        let c = AppConfig(lightsOutHour: 3, dailyPotentialTargetMinutes: 240, variantAnchorDate: now)
        context.insert(c)
        return c
    }
    private func deepWork() -> Habit {
        let h = Habit(name: "Deep work block", kind: .build, usesLoggedDuration: true); context.insert(h); return h
    }
    private func workout() -> Habit {
        let h = Habit(name: "Workout", kind: .build, rewardMinutes: 60); context.insert(h); return h
    }
    private func cigarette() -> Habit {
        let h = Habit(name: "Cigarette", kind: .breakHabit, costMinutes: 30); context.insert(h); return h
    }
    private func log(_ h: Habit, at date: Date, minutes: Int? = nil) {
        context.insert(HabitLog(habit: h, timestamp: date, durationMinutes: minutes))
    }

    // MARK: tests

    func testSnapshotScoresTodaysLogsWithGainFraming() throws {
        let goal = makeGoal(); let config = makeConfig()
        let dw = deepWork(); let wk = workout(); let cig = cigarette()
        log(dw, at: now, minutes: 90)   // +90
        log(wk, at: now)                // +60 flat
        log(cig, at: now)               // −30, +5 honesty

        let habits = [dw, wk, cig]
        let snap = try XCTUnwrap(DayScoreService.snapshot(goal: goal, config: config, habits: habits, now: now))

        XCTAssertEqual(snap.result.grossEarnedMinutes, 150)
        XCTAssertEqual(snap.result.slipMinutes, 30)
        XCTAssertEqual(snap.result.slipCount, 1)
        XCTAssertEqual(snap.result.deepWorkMinutes, 90)
        XCTAssertEqual(snap.result.streakMultiplier, 1.0)      // only today logged → streak 1
        // net = 150 + 5 − 30 = 125 min → kept = 125 × perMinute
        let perMinute = try XCTUnwrap(goal.rates?.perMinute)
        XCTAssertEqual(snap.result.keptAmount, perMinute * 125)
        XCTAssertEqual(snap.variant, .gain)
        XCTAssertEqual(snap.headline.amount, snap.result.keptAmount)
    }

    func testYesterdaysLogsAreExcludedFromToday() throws {
        let goal = makeGoal(); let config = makeConfig()
        let dw = deepWork()
        log(dw, at: daysAgo(1), minutes: 120)   // yesterday — must not count toward today
        log(dw, at: now, minutes: 30)            // today

        let snap = try XCTUnwrap(DayScoreService.snapshot(goal: goal, config: config, habits: [dw], now: now))
        XCTAssertEqual(snap.result.deepWorkMinutes, 30, "only today's 30 min should score")
    }

    func testStreakMultiplierFromConsecutiveLoggedDays() throws {
        let goal = makeGoal(); let config = makeConfig()
        let dw = deepWork()
        // Log a little on each of the last 6 logical days (incl. today) → streak 6 → 1.5×.
        for d in 0...5 { log(dw, at: cal.date(byAdding: .day, value: -d, to: now)!, minutes: (d == 0 ? 100 : 10)) }

        let snap = try XCTUnwrap(DayScoreService.snapshot(goal: goal, config: config, habits: [dw], now: now))
        XCTAssertEqual(snap.result.streakMultiplier, 1.5, accuracy: 1e-9)
        // Today's 100 min × 1.5 = 150 min kept (no slips).
        let perMinute = try XCTUnwrap(goal.rates?.perMinute)
        XCTAssertEqual(snap.result.keptAmount, perMinute * 150)
    }

    func testUpsertPersistsAndPreservesMood() throws {
        let goal = makeGoal(); let config = makeConfig()
        let dw = deepWork()
        log(dw, at: now, minutes: 60)

        // First upsert creates the row.
        let row = try XCTUnwrap(DayScoreStore.upsertToday(goal: goal, config: config, habits: [dw],
                                                          context: context, now: now))
        row.mood = 4
        try context.save()

        // A later recompute (e.g. after another log) must not wipe the mood.
        log(dw, at: now, minutes: 30)
        DayScoreStore.upsertToday(goal: goal, config: config, habits: [dw], context: context, now: now)

        let all = try context.fetch(FetchDescriptor<DayScore>())
        XCTAssertEqual(all.count, 1, "one row per logical day")
        XCTAssertEqual(all.first?.mood, 4, "mood preserved across recompute")
        XCTAssertEqual(all.first?.deepWorkMinutes, 90, "recompute picked up the new log (60+30)")
    }
}
