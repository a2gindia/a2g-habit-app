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
        }
    }
}
#endif
