import Foundation

/// Maps an instant to the *logical* day it belongs to. A logical day runs from
/// `lightsOutHour` to `lightsOutHour` the next calendar day, so a slip at 1am
/// (with a 3am lights-out) counts toward the previous day — matching how the
/// night actually felt.
public struct DayBoundary: Sendable {
    public let lightsOutHour: Int   // 0…23
    public let calendar: Calendar

    public init(lightsOutHour: Int, calendar: Calendar = .current) {
        self.lightsOutHour = min(23, max(0, lightsOutHour))
        self.calendar = calendar
    }

    /// Start instant of the logical day containing `date`.
    public func logicalDayStart(for date: Date) -> Date {
        // lights-out on the same calendar day as `date`
        let sameDayLightsOut = calendar.date(
            bySettingHour: lightsOutHour, minute: 0, second: 0, of: date
        ) ?? calendar.startOfDay(for: date)

        if date < sameDayLightsOut {
            // before lights-out → belongs to the previous logical day
            return calendar.date(byAdding: .day, value: -1, to: sameDayLightsOut) ?? sameDayLightsOut
        }
        return sameDayLightsOut
    }

    /// True when both instants fall in the same logical day.
    public func sameLogicalDay(_ a: Date, _ b: Date) -> Bool {
        logicalDayStart(for: a) == logicalDayStart(for: b)
    }
}
