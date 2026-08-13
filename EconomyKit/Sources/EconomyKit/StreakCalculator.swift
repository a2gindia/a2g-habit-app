import Foundation

/// The streak that drives the earnings multiplier is an **engagement** streak —
/// consecutive logical days on which *anything* was logged — not a "days clean"
/// streak. Rewarding showing-up-and-logging keeps the tracker honest; rewarding
/// days-clean would quietly punish logging a slip, which we never do.
public enum StreakCalculator {

    /// Number of consecutive logical days ending at (and including) `asOf` that
    /// appear in `loggedDayStarts`. Walks backward one logical day at a time and
    /// stops at the first gap.
    ///
    /// - Parameters:
    ///   - loggedDayStarts: set of logical-day-start instants that had ≥1 log
    ///     (from `DayBoundary.logicalDayStart(for:)`).
    ///   - asOf: the logical-day-start to count back from.
    ///   - boundary: provides the calendar used to step days.
    public static func currentStreak(loggedDayStarts: Set<Date>,
                                     asOf: Date,
                                     boundary: DayBoundary) -> Int {
        var streak = 0
        var cursor = boundary.logicalDayStart(for: asOf)
        while loggedDayStarts.contains(cursor) {
            streak += 1
            guard let previous = boundary.calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = boundary.logicalDayStart(for: previous)
        }
        return streak
    }

    /// Earnings multiplier for a given streak length. 1.0 at streak 0–1, then
    /// `+streakMultiplierStep` per additional consecutive day, clamped to
    /// `streakMultiplierCap`. Never below 1.0, never above the cap.
    public static func multiplier(streakDays: Int,
                                  cap: Double = Tuning.streakMultiplierCap,
                                  step: Double = Tuning.streakMultiplierStep) -> Double {
        let growth = step * Double(max(0, streakDays - 1))
        return min(cap, 1.0 + max(0, growth))
    }
}
