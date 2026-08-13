import Foundation
import SwiftData
import EconomyKit

/// Persists computed day scores into `DayScore` rows (upsert by logical day) and
/// maps stored rows to `DayRecord`s for `Metrics`/`Exporter`. Mood is preserved
/// across recomputes — only the user sets it.
enum DayScoreStore {

    /// Upsert the score for the logical day containing `now`, snapshotting the
    /// current logs. Returns the row (also used to attach mood).
    @discardableResult
    static func upsertToday(goal: Goal, config: AppConfig, habits: [Habit],
                            context: ModelContext, now: Date = .now) -> DayScore? {
        guard let snap = DayScoreService.snapshot(goal: goal, config: config, habits: habits, now: now)
        else { return nil }

        let row = fetch(snap.logicalDayStart, context)
            ?? DayScore(logicalDate: snap.logicalDayStart, variant: snap.variant,
                        perMinuteRate: goal.rates?.perMinute ?? 0,
                        potentialZMinutes: config.dailyPotentialTargetMinutes)

        let r = snap.result
        row.variant = snap.variant
        row.perMinuteRate = goal.rates?.perMinute ?? row.perMinuteRate
        row.potentialZMinutes = config.dailyPotentialTargetMinutes
        row.grossEarnedMinutes = r.grossEarnedMinutes
        row.streakMultiplier = r.streakMultiplier
        row.honestyBonusMinutes = r.honestyBonusMinutes
        row.slipMinutes = r.slipMinutes
        row.keptAmount = r.keptAmount
        row.slippedAmount = r.slippedAmount
        row.deepWorkMinutes = r.deepWorkMinutes
        row.slipCount = r.slipCount
        // mood is intentionally left untouched.

        if row.modelContext == nil { context.insert(row) }
        try? context.save()
        return row
    }

    static func fetch(_ logicalDayStart: Date, _ context: ModelContext) -> DayScore? {
        let desc = FetchDescriptor<DayScore>(predicate: #Predicate { $0.logicalDate == logicalDayStart })
        return try? context.fetch(desc).first
    }

    static func record(from ds: DayScore) -> DayRecord {
        DayRecord(logicalDate: ds.logicalDate, variant: ds.variant, perMinuteRate: ds.perMinuteRate,
                  potentialZMinutes: ds.potentialZMinutes, grossEarnedMinutes: ds.grossEarnedMinutes,
                  streakMultiplier: ds.streakMultiplier, honestyBonusMinutes: ds.honestyBonusMinutes,
                  slipMinutes: ds.slipMinutes, deepWorkMinutes: ds.deepWorkMinutes,
                  slipCount: ds.slipCount, keptAmount: ds.keptAmount, slippedAmount: ds.slippedAmount,
                  mood: ds.mood)
    }
}
