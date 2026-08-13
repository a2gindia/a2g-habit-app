import Foundation
import SwiftData
import EconomyKit

/// Bridges the SwiftData layer to the pure `EconomyKit` engines: gathers a logical
/// day's habits + logs, computes the streak and framing variant, and produces the
/// scored result + the framed headline. No persistence — see `DayScoreStore`.
enum DayScoreService {

    struct Snapshot {
        let result: DayScoreResult
        let variant: FramingVariant
        let headline: FramingHeadline
        let logicalDayStart: Date
    }

    /// Live snapshot for the logical day containing `now`. `nil` if the goal has
    /// no valid rate yet.
    static func snapshot(goal: Goal, config: AppConfig, habits: [Habit],
                         now: Date = .now) -> Snapshot? {
        guard let rates = goal.rates else { return nil }
        let boundary = DayBoundary(lightsOutHour: config.lightsOutHour)
        let todayStart = boundary.logicalDayStart(for: now)

        // Stable per-snapshot ids join habits to their logs for the engine.
        var scoringHabits: [ScoringHabit] = []
        var todayLogs: [ScoringLog] = []
        for (i, habit) in habits.enumerated() {
            let id = "h\(i)"
            scoringHabits.append(ScoringHabit(
                id: id, kind: habit.kind,
                rewardMinutes: habit.rewardMinutes,
                usesLoggedDuration: habit.usesLoggedDuration,
                costMinutes: habit.costMinutes,
                targetPerDay: habit.targetPerDay))
            for log in habit.logs where boundary.logicalDayStart(for: log.timestamp) == todayStart {
                todayLogs.append(ScoringLog(habitID: id,
                                            durationMinutes: log.durationMinutes,
                                            loggedLate: log.loggedLate))
            }
        }

        // Engagement streak: consecutive logical days with ≥1 log, up to today.
        let loggedDays = Set(habits.flatMap(\.logs).map { boundary.logicalDayStart(for: $0.timestamp) })
        let streak = StreakCalculator.currentStreak(loggedDayStarts: loggedDays,
                                                    asOf: todayStart, boundary: boundary)
        let multiplier = StreakCalculator.multiplier(streakDays: streak)

        let variant = FramingRotation.variant(for: now, anchor: config.variantAnchorDate, boundary: boundary)

        let result = ScoringEngine.score(
            habits: scoringHabits,
            logs: todayLogs,
            perMinuteRate: rates.perMinute,
            potentialZMinutes: config.dailyPotentialTargetMinutes,
            streakMultiplier: multiplier)

        let headline = FramingPresenter.headline(
            kept: result.keptAmount, slipped: result.slippedAmount,
            potential: result.potentialAmount, variant: variant)

        return Snapshot(result: result, variant: variant, headline: headline, logicalDayStart: todayStart)
    }
}
