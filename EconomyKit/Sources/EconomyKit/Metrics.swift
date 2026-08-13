import Foundation

/// Rolls day-record history into the instrumentation the spec asks for. Pure and
/// deterministic given a fixed calendar.
///
/// A note the spec is explicit about: a *drop* in slips can mean under-reporting
/// rather than improvement, so `avgSlipsPerLoggedDay` must always be read against
/// `avgDeepWorkMinutesPerLoggedDay` — both are surfaced together for that reason.
public enum Metrics {

    public struct AbandonmentGap: Hashable, Sendable {
        public let start: Date   // first inactive logical day
        public let end: Date     // last inactive logical day
        public let days: Int
    }

    public struct Summary: Hashable, Sendable {
        public let daysElapsed: Int
        public let daysLogged: Int
        /// Engagement — the one that matters most. `daysLogged / daysElapsed`.
        public let engagementRate: Double

        public let totalSlips: Int
        public let avgSlipsPerLoggedDay: Double
        public let totalDeepWorkMinutes: Int
        public let avgDeepWorkMinutesPerLoggedDay: Double

        /// Mean mood over days that recorded one; `nil` if none did.
        public let avgMood: Double?

        public let gainDays: Int
        public let lossDays: Int

        /// Gaps of ≥2 consecutive inactive logical days — the abandonment signal.
        public let abandonmentGaps: [AbandonmentGap]
    }

    public static func summarize(records: [DayRecord],
                                 from: Date,
                                 to: Date,
                                 boundary: DayBoundary) -> Summary {
        let start = boundary.logicalDayStart(for: from)
        let end = boundary.logicalDayStart(for: to)

        // Elapsed logical days, in order.
        var elapsedDays: [Date] = []
        var cursor = start
        var guardCount = 0
        while cursor <= end, guardCount < 100_000 {
            elapsedDays.append(cursor)
            guard let next = boundary.calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            guardCount += 1
        }

        // Active days within the window.
        let inWindow = records.filter {
            let d = boundary.logicalDayStart(for: $0.logicalDate)
            return d >= start && d <= end
        }
        let activeDays = Set(inWindow.filter(\.isActive)
            .map { boundary.logicalDayStart(for: $0.logicalDate) })
        let loggedRecords = inWindow.filter(\.isActive)

        let daysLogged = activeDays.count
        let daysElapsed = elapsedDays.count

        let totalSlips = loggedRecords.reduce(0) { $0 + $1.slipCount }
        let totalDeepWork = loggedRecords.reduce(0) { $0 + $1.deepWorkMinutes }
        let moods = loggedRecords.compactMap(\.mood)

        return Summary(
            daysElapsed: daysElapsed,
            daysLogged: daysLogged,
            engagementRate: daysElapsed > 0 ? Double(daysLogged) / Double(daysElapsed) : 0,
            totalSlips: totalSlips,
            avgSlipsPerLoggedDay: daysLogged > 0 ? Double(totalSlips) / Double(daysLogged) : 0,
            totalDeepWorkMinutes: totalDeepWork,
            avgDeepWorkMinutesPerLoggedDay: daysLogged > 0 ? Double(totalDeepWork) / Double(daysLogged) : 0,
            avgMood: moods.isEmpty ? nil : Double(moods.reduce(0, +)) / Double(moods.count),
            gainDays: loggedRecords.filter { $0.variant == .gain }.count,
            lossDays: loggedRecords.filter { $0.variant == .loss }.count,
            abandonmentGaps: gaps(in: elapsedDays, activeDays: activeDays))
    }

    private static func gaps(in elapsedDays: [Date], activeDays: Set<Date>) -> [AbandonmentGap] {
        var result: [AbandonmentGap] = []
        var runStart: Date?
        var runEnd: Date?
        var runLen = 0

        func flush() {
            if runLen >= 2, let s = runStart, let e = runEnd {
                result.append(AbandonmentGap(start: s, end: e, days: runLen))
            }
            runStart = nil; runEnd = nil; runLen = 0
        }

        for day in elapsedDays {
            if activeDays.contains(day) {
                flush()
            } else {
                if runStart == nil { runStart = day }
                runEnd = day
                runLen += 1
            }
        }
        flush()   // trailing gap
        return result
    }
}
