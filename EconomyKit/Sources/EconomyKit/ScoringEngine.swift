import Foundation

/// A habit's scoring parameters, flattened for the engine (no SwiftData).
public struct ScoringHabit: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: HabitKind
    /// Flat minutes credited per counted completion (`.build`, non-duration).
    public let rewardMinutes: Int
    /// Deep-work style: earn from each log's `durationMinutes` instead of a flat reward.
    public let usesLoggedDuration: Bool
    /// Minutes burned per slip (`.breakHabit`).
    public let costMinutes: Int
    /// Max flat completions credited per day. `nil` → capped at 1 (no tap-farming).
    public let targetPerDay: Int?

    public init(id: String, kind: HabitKind, rewardMinutes: Int = 0,
                usesLoggedDuration: Bool = false, costMinutes: Int = 0,
                targetPerDay: Int? = nil) {
        self.id = id
        self.kind = kind
        self.rewardMinutes = rewardMinutes
        self.usesLoggedDuration = usesLoggedDuration
        self.costMinutes = costMinutes
        self.targetPerDay = targetPerDay
    }
}

/// One log entry, flattened for the engine.
public struct ScoringLog: Hashable, Sendable {
    public let habitID: String
    public let durationMinutes: Int?   // deep-work duration; nil otherwise
    public let loggedLate: Bool        // informational; honesty bonus is flat per slip

    public init(habitID: String, durationMinutes: Int? = nil, loggedLate: Bool = false) {
        self.habitID = habitID
        self.durationMinutes = durationMinutes
        self.loggedLate = loggedLate
    }
}

/// The computed roll-up for one logical day. The app maps this onto a `DayScore`
/// (adding date, variant, rate, mood). All money is full-precision `Decimal`;
/// rounding happens only at display.
public struct DayScoreResult: Hashable, Sendable {
    public let grossEarnedMinutes: Int      // build + deep work, before multiplier
    public let streakMultiplier: Double
    public let honestyBonusMinutes: Int     // total credited across all slips
    public let slipMinutes: Int             // total burned by slips
    public let deepWorkMinutes: Int
    public let slipCount: Int

    public let potentialAmount: Decimal     // Z minutes × rate
    public let keptAmount: Decimal          // floored at 0 — the only headline source
    public let slippedAmount: Decimal       // max(0, potential − kept)
}

/// Rolls a logical day's logs into a `DayScoreResult`.
///
/// Order of operations (matters for the zero-floor):
/// 1. Gross behavioural earnings in minutes (build completions capped against
///    farming; deep work from logged duration).
/// 2. Streak multiplier applied to **earnings only**.
/// 3. Honesty bonus added flat (not multiplied — integrity isn't a performance stat).
/// 4. Slip costs subtracted.
/// 5. **Floor the net at zero.** No negative balance ever reaches the model.
public enum ScoringEngine {

    public static func score(habits: [ScoringHabit],
                             logs: [ScoringLog],
                             perMinuteRate: Decimal,
                             potentialZMinutes: Int,
                             streakMultiplier: Double,
                             honestyBonusMinutes: Int = Tuning.honestyBonusMinutes) -> DayScoreResult {

        let habitsByID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        let logsByHabit = Dictionary(grouping: logs, by: \.habitID)

        var grossEarnedMinutes = 0
        var deepWorkMinutes = 0
        var slipMinutes = 0
        var slipCount = 0

        for (habitID, habitLogs) in logsByHabit {
            guard let habit = habitsByID[habitID] else { continue }

            switch habit.kind {
            case .build:
                if habit.usesLoggedDuration {
                    // Deep work: sum actual minutes. No farming cap — duration is
                    // self-limiting (you can't fake hours you didn't spend).
                    let minutes = habitLogs.reduce(0) { $0 + max(0, $1.durationMinutes ?? 0) }
                    grossEarnedMinutes += minutes
                    deepWorkMinutes += minutes
                } else {
                    // Flat reward: credit up to targetPerDay (default 1) completions.
                    let cap = habit.targetPerDay ?? 1
                    let credited = min(habitLogs.count, max(0, cap))
                    grossEarnedMinutes += credited * habit.rewardMinutes
                }

            case .breakHabit:
                // Every logged slip burns its cost. Logging itself is neutral;
                // the cost is on the behaviour, softened by the honesty bonus.
                slipCount += habitLogs.count
                slipMinutes += habitLogs.count * max(0, habit.costMinutes)
            }
        }

        let honestyMinutes = slipCount * max(0, honestyBonusMinutes)

        // Money math in Decimal. Streak multiplies earnings only.
        let clampedMultiplier = min(Tuning.streakMultiplierCap, max(1.0, streakMultiplier))
        let earnedAfterStreak = Decimal(grossEarnedMinutes) * Decimal(clampedMultiplier)
        let netMinutes = earnedAfterStreak + Decimal(honestyMinutes) - Decimal(slipMinutes)
        let keptMinutes = max(0, netMinutes)                       // ← zero floor

        let potentialAmount = Decimal(max(0, potentialZMinutes)) * perMinuteRate
        let keptAmount = keptMinutes * perMinuteRate
        let slippedAmount = max(0, potentialAmount - keptAmount)   // never negative

        return DayScoreResult(grossEarnedMinutes: grossEarnedMinutes,
                              streakMultiplier: clampedMultiplier,
                              honestyBonusMinutes: honestyMinutes,
                              slipMinutes: slipMinutes,
                              deepWorkMinutes: deepWorkMinutes,
                              slipCount: slipCount,
                              potentialAmount: potentialAmount,
                              keptAmount: keptAmount,
                              slippedAmount: slippedAmount)
    }
}
