import Foundation

/// Every economy magic number lives here and nowhere else. Views and models
/// read these; they never hardcode a constant. Tune the app from this one file.
public enum Tuning {

    // MARK: Time-value engine

    /// Working-hours weeks per year. Fixed at 52 so `8h × 5d × 52 × 5y = 10,400 h`
    /// matches the spec's worked example. (Not 52.143 — the round number is
    /// intentional and documented.)
    public static let weeksPerYear: Decimal = 52

    /// Calendar days per year for `.calendarHours`. Leap years are ignored so
    /// `365 × 24 × 5 = 43,800 h` matches the spec's worked example.
    public static let daysPerYear: Decimal = 365

    // MARK: Scoring (used from slice 4 onward — parked here now so nothing
    // downstream ever invents its own constant)

    /// Streak multiplier ceiling. Applies to *earnings only*, before deductions.
    /// Capped so it can never grow unbounded.
    public static let streakMultiplierCap: Double = 1.5

    /// Per-consecutive-day growth of the streak multiplier. 1.0 at streak 1,
    /// +0.1 each further day, hitting the 1.5 cap at a 6-day streak.
    public static let streakMultiplierStep: Double = 0.1

    /// Flat honesty credit (in minutes) for logging a break-habit slip. Must be
    /// strictly positive and strictly less than the smallest slip cost, so that
    /// logging is always the cheaper move but a slip still stings. Enforced by a
    /// test once slip costs land in slice 3/4.
    public static let honestyBonusMinutes: Int = 5

    // MARK: Day boundary & daily potential (defaults; overridable via AppConfig)

    /// Day rollover hour for scoring, streaks, and weekly framing rotation.
    /// A slip at 1am counts toward the *previous* logical day.
    public static let defaultLightsOutHour: Int = 3

    /// Defines the daily potential `Z` (in minutes) that the framing headline is
    /// measured against: `Z_amount = dailyPotentialTargetMinutes × perMinuteRate`.
    /// Default is 4 focused hours.
    public static let defaultDailyPotentialTargetMinutes: Int = 240
}
