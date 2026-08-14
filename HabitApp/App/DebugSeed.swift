#if DEBUG
import Foundation
import SwiftData
import EconomyKit

/// Dev-only seeding, gated behind a launch env var so it never touches normal
/// runs. Lets the simulator be launched straight into a populated state for
/// screenshots / manual testing without tapping through onboarding:
///
///   SIMCTL_CHILD_SEED_DEMO_GOAL=1 xcrun simctl launch <device> <bundle-id>
enum DebugSeed {
    static func seedIfNeeded(_ context: ModelContext) {
        guard ProcessInfo.processInfo.environment["SEED_DEMO_GOAL"] == "1" else { return }
        let existing = try? context.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.isActive }))
        guard (existing?.isEmpty ?? true) else { return }

        let goal = Goal(targetAmount: 1_000_000_000, horizonYears: 5, denominator: .calendarHours)
        context.insert(goal)
        _ = AppConfig.current(in: context)
        try? context.save()

        // Screenshot-only: add a little of today's activity so the headline/insights
        // aren't empty. Separate flag so it never perturbs the UI tests (which
        // rely on a clean ₹0 start under SEED_DEMO_GOAL alone).
        if ProcessInfo.processInfo.environment["SEED_DEMO_LOGS"] == "1" {
            let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            func habit(_ name: String) -> Habit? { habits.first { $0.name == name } }
            if let dw = habit("Deep work block") {
                context.insert(HabitLog(habit: dw, durationMinutes: 90))
            }
            if let workout = habit("Workout") {
                context.insert(HabitLog(habit: workout))
            }
            if let cig = habit("Cigarette") {
                context.insert(HabitLog(habit: cig))
            }
            try? context.save()

            // Persist today's DayScore so Insights has data even if Today isn't opened.
            let config = AppConfig.current(in: context)
            let allHabits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            DayScoreStore.upsertToday(goal: goal, config: config, habits: allHabits, context: context)

            seedPastDays(goal: goal, config: config, context: context)
        }
    }

    /// A handful of prior days so History and the trend chart have shape.
    private static func seedPastDays(goal: Goal, config: AppConfig, context: ModelContext) {
        let cal = Calendar.current
        let now = Date()
        let boundary = DayBoundary(lightsOutHour: config.lightsOutHour)
        let perMinute = goal.rates?.perMinute ?? 0
        let z = config.dailyPotentialTargetMinutes
        let potential = Decimal(z) * perMinute

        // (days-ago, kept minutes, slips, deep-work minutes, mood)
        let samples: [(Int, Int, Int, Int, Int?)] = [
            (1, 200, 1, 120, 4), (2, 80, 3, 60, 2), (3, 240, 0, 180, 5),
            (4, 0, 4, 0, 1), (5, 150, 1, 90, 3), (6, 190, 2, 100, 4),
        ]
        for (ago, keptMin, slips, deep, mood) in samples {
            guard let date = cal.date(byAdding: .day, value: -ago, to: now) else { continue }
            let start = boundary.logicalDayStart(for: date)
            let kept = Decimal(keptMin) * perMinute
            let ds = DayScore(
                logicalDate: start,
                variant: FramingRotation.variant(for: start, anchor: config.variantAnchorDate, boundary: boundary),
                perMinuteRate: perMinute, potentialZMinutes: z,
                grossEarnedMinutes: deep, streakMultiplier: 1.0,
                honestyBonusMinutes: slips * 5, slipMinutes: slips * 30,
                keptAmount: kept, slippedAmount: max(0, potential - kept),
                deepWorkMinutes: deep, slipCount: slips, mood: mood)
            context.insert(ds)
        }
        try? context.save()
    }
}
#endif
