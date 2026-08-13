import Foundation

/// How the goal's horizon is converted into a pool of hours. This is a **user
/// setting, not a constant** — it changes the entire emotional weight of the
/// per-hour number.
///
/// Codable with associated values so a SwiftData `@Model` can persist it inline.
public enum Denominator: Codable, Hashable, Sendable {

    /// Every hour of the horizon counts. 5y → 365·24·5 = 43,800 h.
    case calendarHours

    /// Only working hours count. 8h × 5d over 5y → ~10,400 h.
    /// `weeksPerYear` is fixed at 52 (see `TimeValueEngine`).
    case workingHours(perDay: Double, daysPerWeek: Int)

    /// A hand-set pool of hours. **Ignores `horizonYears`** — this case is the
    /// source of truth for its own total, resolving the dead-field ambiguity
    /// where a Goal carries both a horizon and a custom hour count.
    case custom(totalHours: Double)
}
