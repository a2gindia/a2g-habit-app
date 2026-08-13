import Foundation
import SwiftData
import EconomyKit

/// The end-of-day roll-up for one *logical* day (keyed to the lights-out
/// boundary, not calendar midnight). One per day.
///
/// Rate and potential are **snapshotted** at roll-up so that changing the goal
/// later never rewrites history — essential for the framing A/B data to stay
/// attributable.
@Model
final class DayScore {
    /// Start of the logical day this score covers. Unique key.
    @Attribute(.unique) var logicalDate: Date

    /// Framing lens active for this day — stamped for attribution.
    var variant: FramingVariant

    // MARK: Snapshots (frozen at roll-up)

    var perMinuteRate: Decimal
    /// The daily potential `Z`, in minutes. `Z_amount = potentialZMinutes × perMinuteRate`.
    var potentialZMinutes: Int

    // MARK: Economy (minutes, then money)

    var grossEarnedMinutes: Int      // before streak multiplier and deductions
    var streakMultiplier: Double     // ≤ Tuning.streakMultiplierCap; earnings only
    var honestyBonusMinutes: Int
    var slipMinutes: Int             // total minutes burned by slips this day

    /// The floored, kept amount — `max(0, earned − slips)` in ₹. The ONLY source
    /// for the primary headline in either framing.
    var keptAmount: Decimal
    /// What slipped, measured against potential: `Z_amount − keptAmount`. Drives
    /// the `.loss` copy. Can be large on a bad day even though `keptAmount`
    /// floored at zero — that is the honest reading.
    var slippedAmount: Decimal

    // MARK: Instrumentation

    var deepWorkMinutes: Int
    var slipCount: Int
    var mood: Int?                   // 1–5, one end-of-day tap

    init(logicalDate: Date,
         variant: FramingVariant,
         perMinuteRate: Decimal,
         potentialZMinutes: Int,
         grossEarnedMinutes: Int = 0,
         streakMultiplier: Double = 1.0,
         honestyBonusMinutes: Int = 0,
         slipMinutes: Int = 0,
         keptAmount: Decimal = 0,
         slippedAmount: Decimal = 0,
         deepWorkMinutes: Int = 0,
         slipCount: Int = 0,
         mood: Int? = nil) {
        self.logicalDate = logicalDate
        self.variant = variant
        self.perMinuteRate = perMinuteRate
        self.potentialZMinutes = potentialZMinutes
        self.grossEarnedMinutes = grossEarnedMinutes
        self.streakMultiplier = streakMultiplier
        self.honestyBonusMinutes = honestyBonusMinutes
        self.slipMinutes = slipMinutes
        self.keptAmount = keptAmount
        self.slippedAmount = slippedAmount
        self.deepWorkMinutes = deepWorkMinutes
        self.slipCount = slipCount
        self.mood = mood
    }
}
