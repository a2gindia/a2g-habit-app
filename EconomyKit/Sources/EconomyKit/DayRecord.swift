import Foundation

/// A pure, Codable snapshot of one `DayScore`. The app maps its SwiftData
/// `DayScore` rows onto these; `Metrics` and `Exporter` work only on records, so
/// instrumentation stays testable without SwiftData/Xcode.
public struct DayRecord: Hashable, Sendable, Codable {
    public let logicalDate: Date
    public let variant: FramingVariant
    public let perMinuteRate: Decimal
    public let potentialZMinutes: Int
    public let grossEarnedMinutes: Int
    public let streakMultiplier: Double
    public let honestyBonusMinutes: Int
    public let slipMinutes: Int
    public let deepWorkMinutes: Int
    public let slipCount: Int
    public let keptAmount: Decimal
    public let slippedAmount: Decimal
    public let mood: Int?

    public init(logicalDate: Date, variant: FramingVariant, perMinuteRate: Decimal,
                potentialZMinutes: Int, grossEarnedMinutes: Int, streakMultiplier: Double,
                honestyBonusMinutes: Int, slipMinutes: Int, deepWorkMinutes: Int,
                slipCount: Int, keptAmount: Decimal, slippedAmount: Decimal, mood: Int?) {
        self.logicalDate = logicalDate
        self.variant = variant
        self.perMinuteRate = perMinuteRate
        self.potentialZMinutes = potentialZMinutes
        self.grossEarnedMinutes = grossEarnedMinutes
        self.streakMultiplier = streakMultiplier
        self.honestyBonusMinutes = honestyBonusMinutes
        self.slipMinutes = slipMinutes
        self.deepWorkMinutes = deepWorkMinutes
        self.slipCount = slipCount
        self.keptAmount = keptAmount
        self.slippedAmount = slippedAmount
        self.mood = mood
    }

    /// A day "counts as logged" if it shows any real activity or a mood tap.
    /// Engagement — the metric that matters most — is built on this.
    public var isActive: Bool {
        grossEarnedMinutes > 0 || deepWorkMinutes > 0 || slipCount > 0 || mood != nil
    }
}
