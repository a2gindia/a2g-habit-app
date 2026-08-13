import Foundation

/// Assigns the active framing variant by *logical* week, alternating so every
/// week of usage is one clean data point. Even weeks since the anchor → `.gain`,
/// odd → `.loss`. Prior going in: expect `.gain` to win — but you're n=1, so ship
/// both and let your own exported data decide.
public enum FramingRotation {

    /// The variant active on the logical day containing `date`.
    ///
    /// Uses `DayBoundary` so a 1am session is scored under the same week as the
    /// evening before it, never flipping variants mid-night.
    public static func variant(for date: Date,
                               anchor: Date,
                               boundary: DayBoundary) -> FramingVariant {
        let weeks = weekIndex(for: date, anchor: anchor, boundary: boundary)
        return weeks % 2 == 0 ? .gain : .loss
    }

    /// Whole logical weeks between the anchor's logical day and `date`'s. Clamped
    /// at 0 for dates before the anchor.
    public static func weekIndex(for date: Date,
                                 anchor: Date,
                                 boundary: DayBoundary) -> Int {
        let anchorStart = boundary.logicalDayStart(for: anchor)
        let dateStart = boundary.logicalDayStart(for: date)
        let days = boundary.calendar.dateComponents([.day], from: anchorStart, to: dateStart).day ?? 0
        return max(0, days / 7)
    }
}
