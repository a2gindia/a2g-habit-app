import SwiftUI
import SwiftData
import EconomyKit
import UniformTypeIdentifiers

/// Surfaces the instrumentation and lets you export the raw day-record history to
/// a file (CSV/JSON) for off-device analysis — the week-1 "metrics recording to a
/// local store you can export" requirement.
struct InsightsView: View {
    @Query private var configs: [AppConfig]
    @Query(sort: \DayScore.logicalDate) private var dayScores: [DayScore]

    private var boundary: DayBoundary {
        DayBoundary(lightsOutHour: configs.first?.lightsOutHour ?? Tuning.defaultLightsOutHour)
    }
    private var records: [DayRecord] { dayScores.map(DayScoreStore.record) }

    private var summary: Metrics.Summary? {
        guard let first = dayScores.first?.logicalDate else { return nil }
        return Metrics.summarize(records: records, from: first, to: .now, boundary: boundary)
    }

    var body: some View {
        NavigationStack {
            List {
                if let s = summary {
                    Section("Engagement") {
                        stat("Days logged", "\(s.daysLogged) / \(s.daysElapsed)")
                        stat("Engagement rate", percent(s.engagementRate))
                        stat("Abandonment gaps (2+ days)", "\(s.abandonmentGaps.count)")
                    }
                    Section("Behaviour") {
                        stat("Deep work / logged day", "\(Int(s.avgDeepWorkMinutesPerLoggedDay)) min")
                        stat("Slips / logged day", String(format: "%.1f", s.avgSlipsPerLoggedDay))
                        stat("Avg mood", s.avgMood.map { String(format: "%.1f", $0) } ?? "—")
                    }
                    Section("A/B framing") {
                        stat("Gain days", "\(s.gainDays)")
                        stat("Loss days", "\(s.lossDays)")
                    }
                } else {
                    ContentUnavailableView("No data yet", systemImage: "chart.bar",
                        description: Text("Log habits and check the dashboard to start recording days."))
                }

                Section("Export") {
                    // Serialization is deferred into the Transferable — it runs only
                    // when the user actually shares, not on every appearance.
                    ShareLink(item: CSVDocument(records: records),
                              preview: SharePreview("Habit data (CSV)")) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    ShareLink(item: JSONDocument(records: records),
                              preview: SharePreview("Habit data (JSON)")) {
                        Label("Export JSON", systemImage: "curlybraces")
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
    }
    private func percent(_ x: Double) -> String { "\(Int((x * 100).rounded()))%" }
}

// MARK: - Lazy export documents

private struct CSVDocument: Transferable, Sendable {
    let records: [DayRecord]
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            Data(Exporter.csv(doc.records).utf8)
        }
        .suggestedFileName("habit-export.csv")
    }
}

private struct JSONDocument: Transferable, Sendable {
    let records: [DayRecord]
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { doc in
            Data(try Exporter.json(doc.records).utf8)
        }
        .suggestedFileName("habit-export.json")
    }
}
