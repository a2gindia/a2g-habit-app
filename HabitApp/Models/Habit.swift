import Foundation
import SwiftData
import EconomyKit

/// A tracked behaviour. All scoring is expressed in **minutes** (the internal
/// economy unit); minutes convert to ₹ only at display, via the goal's
/// per-minute rate. This is what makes "time-value derived" coherent.
@Model
final class Habit {
    var name: String

    /// Neutral display label layer. `name` may be blunt ("porn"); `displayLabel`
    /// lets the UI and App Store screenshots show something softer without losing
    /// the honest underlying identity. Falls back to `name` when nil.
    var displayLabel: String?

    var kind: HabitKind
    var targetPerDay: Int?           // build only; caps daily reward credits

    // MARK: Scoring inputs (minutes)

    /// Flat reward for completing a build habit. `0` when the habit earns from
    /// logged duration instead (see `usesLoggedDuration`).
    var rewardMinutes: Int

    /// Deep-work style: earn from `HabitLog.durationMinutes` rather than a flat
    /// reward. Only meaningful for `.build`.
    var usesLoggedDuration: Bool

    /// Minutes burned per logged slip. Only meaningful for `.breakHabit`.
    /// Must exceed `Tuning.honestyBonusMinutes` so honest logging still nets a
    /// cost (enforced by test in slice 4).
    var costMinutes: Int

    var sortOrder: Int

    /// Archived habits are hidden from logging but keep their history — deleting
    /// would cascade away the logs. Default keeps existing rows active (lightweight
    /// migration).
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog] = []

    init(name: String,
         displayLabel: String? = nil,
         kind: HabitKind,
         targetPerDay: Int? = nil,
         rewardMinutes: Int = 0,
         usesLoggedDuration: Bool = false,
         costMinutes: Int = 0,
         sortOrder: Int = 0,
         isArchived: Bool = false) {
        self.name = name
        self.displayLabel = displayLabel
        self.kind = kind
        self.targetPerDay = targetPerDay
        self.rewardMinutes = rewardMinutes
        self.usesLoggedDuration = usesLoggedDuration
        self.costMinutes = costMinutes
        self.sortOrder = sortOrder
        self.isArchived = isArchived
    }

    var label: String { displayLabel ?? name }
}
