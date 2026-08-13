import Foundation
import SwiftData
import EconomyKit

/// Seeds the personal-build default habits once. Scoring magnitudes (minutes) are
/// starting defaults — tune freely; they live only here and on each `Habit`.
///
/// Break-habit costs are all kept above `Tuning.honestyBonusMinutes` so honest
/// logging still nets a cost (the slice-4 invariant).
enum HabitSeeder {
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Habit>())) ?? 0
        guard count == 0 else { return }

        for habit in defaults { context.insert(habit) }
        try? context.save()
    }

    static var defaults: [Habit] {
        [
            // Build — flat reward unless duration-based.
            Habit(name: "Workout", kind: .build, rewardMinutes: 60, sortOrder: 0),
            Habit(name: "Shower after workout", kind: .build, rewardMinutes: 10, sortOrder: 1),
            Habit(name: "Cooked meal", kind: .build, targetPerDay: 3, rewardMinutes: 20, sortOrder: 2),
            Habit(name: "Deep work block", kind: .build, usesLoggedDuration: true, sortOrder: 3),
            Habit(name: "Lights-out on time", kind: .build, rewardMinutes: 30, sortOrder: 4),

            // Break — cost per slip (minutes burned).
            Habit(name: "Doomscroll session", kind: .breakHabit, costMinutes: 20, sortOrder: 5),
            Habit(name: "Porn", displayLabel: "Explicit content", kind: .breakHabit, costMinutes: 30, sortOrder: 6),
            Habit(name: "Cigarette", kind: .breakHabit, costMinutes: 30, sortOrder: 7),
            Habit(name: "Late-night phone", kind: .breakHabit, costMinutes: 20, sortOrder: 8),
        ]
    }
}
