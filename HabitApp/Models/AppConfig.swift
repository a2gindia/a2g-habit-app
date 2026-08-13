import Foundation
import SwiftData
import EconomyKit

/// Single-row app configuration. User-tunable settings that aren't part of the
/// goal itself. Create exactly one; `AppConfig.current(in:)` enforces that.
@Model
final class AppConfig {
    /// Day rollover hour (0–23). A slip before this hour counts toward the
    /// previous logical day. Default from `Tuning`.
    var lightsOutHour: Int

    /// Defines the daily potential `Z` in minutes. Default from `Tuning`.
    var dailyPotentialTargetMinutes: Int

    /// Anchor for weekly framing rotation. Week index = whole weeks since this
    /// date; even → `.gain`, odd → `.loss` (rotation logic lands in slice 5).
    var variantAnchorDate: Date

    init(lightsOutHour: Int = Tuning.defaultLightsOutHour,
         dailyPotentialTargetMinutes: Int = Tuning.defaultDailyPotentialTargetMinutes,
         variantAnchorDate: Date = .now) {
        self.lightsOutHour = lightsOutHour
        self.dailyPotentialTargetMinutes = dailyPotentialTargetMinutes
        self.variantAnchorDate = variantAnchorDate
    }

    /// Fetches the single config row, creating and inserting it on first run.
    static func current(in context: ModelContext) -> AppConfig {
        let existing = try? context.fetch(FetchDescriptor<AppConfig>())
        if let config = existing?.first { return config }
        let config = AppConfig()
        context.insert(config)
        return config
    }
}
