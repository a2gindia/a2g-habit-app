import Foundation

/// A pure, value-type snapshot of the inputs the time-value math needs. The
/// SwiftData `Goal` model produces one of these; the engine never touches the
/// `@Model` directly, which is what keeps the math unit-testable without Xcode.
public struct GoalParameters: Hashable, Sendable {
    public let targetAmount: Decimal
    public let horizonYears: Double
    public let denominator: Denominator

    public init(targetAmount: Decimal, horizonYears: Double, denominator: Denominator) {
        self.targetAmount = targetAmount
        self.horizonYears = horizonYears
        self.denominator = denominator
    }
}
