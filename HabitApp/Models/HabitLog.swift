import Foundation
import SwiftData

/// A single logged event: a build completion or a break-habit slip.
///
/// Logging a slip is a neutral, factual act — it never itself deducts. The
/// deduction is scored against the *behaviour* at roll-up; logging late or
/// logging a hideable slip earns an honesty bonus (`loggedLate`), so telling the
/// truth is always the cheaper move.
@Model
final class HabitLog {
    var habit: Habit?
    var timestamp: Date

    /// Minutes for duration-based build habits (deep work). `nil` for flat-reward
    /// completions and for slips.
    var durationMinutes: Int?

    var note: String?

    /// True when logged after the fact rather than in the moment. Drives the
    /// honesty bonus; it is never a penalty.
    var loggedLate: Bool

    init(habit: Habit?,
         timestamp: Date = .now,
         durationMinutes: Int? = nil,
         note: String? = nil,
         loggedLate: Bool = false) {
        self.habit = habit
        self.timestamp = timestamp
        self.durationMinutes = durationMinutes
        self.note = note
        self.loggedLate = loggedLate
    }
}
