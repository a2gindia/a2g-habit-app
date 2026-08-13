import Foundation

/// The derived time-value of the goal. All values are `Decimal` and carry full
/// precision — rounding happens only at display (`MoneyFormatting`). This is the
/// pacing metaphor, not a forecast; the honesty screen says so out loud.
public struct Rates: Hashable, Sendable {
    public let totalHours: Decimal
    public let perHour: Decimal
    public let perMinute: Decimal
    public let perSecond: Decimal
}

/// Converts a `GoalParameters` into a pool of hours and the per-hour/minute/second
/// rates. Pure and Xcode-free — this is the load-bearing math the whole app hangs
/// off, so it is fully unit-tested.
public enum TimeValueEngine {

    /// Total hours implied by the horizon and denominator. `nil` when the inputs
    /// can't yield a positive pool (non-positive horizon or custom hours), which
    /// callers must treat as "goal not yet configurable" rather than dividing by
    /// zero.
    public static func totalHours(for params: GoalParameters) -> Decimal? {
        let hours: Decimal
        switch params.denominator {
        case .calendarHours:
            guard params.horizonYears > 0 else { return nil }
            hours = Decimal(params.horizonYears) * Tuning.daysPerYear * 24

        case let .workingHours(perDay, daysPerWeek):
            guard params.horizonYears > 0, perDay > 0, daysPerWeek > 0 else { return nil }
            hours = Decimal(perDay)
                * Decimal(daysPerWeek)
                * Tuning.weeksPerYear
                * Decimal(params.horizonYears)

        case let .custom(totalHours):
            // Intentionally ignores horizonYears — this case owns its total.
            guard totalHours > 0 else { return nil }
            hours = Decimal(totalHours)
        }
        return hours > 0 ? hours : nil
    }

    /// The full rate set, or `nil` if the goal isn't configurable yet
    /// (non-positive target or hour pool).
    public static func rates(for params: GoalParameters) -> Rates? {
        guard params.targetAmount > 0,
              let hours = totalHours(for: params) else { return nil }

        let perHour = params.targetAmount / hours
        let perMinute = perHour / 60
        let perSecond = perMinute / 60
        return Rates(totalHours: hours,
                     perHour: perHour,
                     perMinute: perMinute,
                     perSecond: perSecond)
    }
}
