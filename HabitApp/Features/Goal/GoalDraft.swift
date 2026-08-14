import Foundation
import EconomyKit

/// Editable working copy of a goal's inputs, shared by the onboarding setup and
/// the post-onboarding editor. Holds field state for all denominator kinds so
/// switching between them keeps sensible values, and derives the live rate.
struct GoalDraft {
    var targetAmount: Decimal = 1_000_000_000     // 100 cr
    var horizonYears: Double = 5
    var kind: Kind = .calendarHours
    var workPerDay: Double = 8
    var workDaysPerWeek: Int = 5
    var customHours: Double = 10_000

    enum Kind: String, CaseIterable, Identifiable {
        case calendarHours = "Calendar"
        case workingHours = "Working"
        case custom = "Custom"
        var id: String { rawValue }
    }

    init() {}

    /// Seed the draft from an existing goal (reverses the denominator enum).
    init(goal: Goal) {
        targetAmount = goal.targetAmount
        horizonYears = goal.horizonYears
        switch goal.denominator {
        case .calendarHours:
            kind = .calendarHours
        case .workingHours(let perDay, let daysPerWeek):
            kind = .workingHours; workPerDay = perDay; workDaysPerWeek = daysPerWeek
        case .custom(let totalHours):
            kind = .custom; customHours = totalHours
        }
    }

    var denominator: Denominator {
        switch kind {
        case .calendarHours: return .calendarHours
        case .workingHours:  return .workingHours(perDay: workPerDay, daysPerWeek: workDaysPerWeek)
        case .custom:        return .custom(totalHours: customHours)
        }
    }

    var rates: Rates? {
        TimeValueEngine.rates(for: GoalParameters(targetAmount: targetAmount,
                                                  horizonYears: horizonYears,
                                                  denominator: denominator))
    }
}
