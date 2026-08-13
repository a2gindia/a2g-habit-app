import Foundation

/// A habit is either something you're trying to *do more of* (build) or *do
/// less of* (break). The two are scored in opposite directions.
///
/// `String`-backed so SwiftData stores it natively and exports read cleanly.
/// The case is named `breakHabit` because `break` is a Swift keyword; the
/// stored/exported raw value is still `"break"`.
public enum HabitKind: String, Codable, Hashable, Sendable, CaseIterable {
    case build
    case breakHabit = "break"
}
