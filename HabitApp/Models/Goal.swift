import Foundation
import SwiftData
import EconomyKit

/// The user's target and horizon. One goal is active at a time; older goals are
/// kept (never rewritten) so historical `DayScore` snapshots stay attributable.
@Model
final class Goal {
    var targetAmount: Decimal        // e.g. 1_000_000_000 (100 cr)
    var currencyCode: String         // "INR" in v1
    var horizonYears: Double         // e.g. 5
    var denominator: Denominator     // user setting — reshapes the whole app
    var startDate: Date
    var isActive: Bool

    init(targetAmount: Decimal,
         currencyCode: String = "INR",
         horizonYears: Double,
         denominator: Denominator,
         startDate: Date = .now,
         isActive: Bool = true) {
        self.targetAmount = targetAmount
        self.currencyCode = currencyCode
        self.horizonYears = horizonYears
        self.denominator = denominator
        self.startDate = startDate
        self.isActive = isActive
    }

    /// Pure value snapshot handed to `TimeValueEngine`. The engine never sees the
    /// `@Model` — this is the seam that keeps the math testable without Xcode.
    var parameters: GoalParameters {
        GoalParameters(targetAmount: targetAmount,
                       horizonYears: horizonYears,
                       denominator: denominator)
    }

    /// Convenience: derived rates, or `nil` if the goal isn't configurable yet.
    var rates: Rates? { TimeValueEngine.rates(for: parameters) }
}
