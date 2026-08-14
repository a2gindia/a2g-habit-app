import SwiftUI
import SwiftData
import Charts
import EconomyKit

/// Day-by-day history: a switchable trend chart over recent days plus a list of
/// every recorded day, each tappable for the full breakdown.
struct HistoryView: View {
    @Query(sort: \DayScore.logicalDate, order: .reverse) private var days: [DayScore]
    @State private var metric: TrendMetric = .kept

    /// Oldest→newest, last 30, for the chart's x-axis.
    private var recent: [DayScore] {
        Array(days.prefix(30)).sorted { $0.logicalDate < $1.logicalDate }
    }

    var body: some View {
        List {
            if days.count >= 2 {
                Section("Trend") {
                    Picker("Metric", selection: $metric) {
                        ForEach(TrendMetric.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Chart(recent) { day in
                        BarMark(
                            x: .value("Day", day.logicalDate, unit: .day),
                            y: .value(metric.title, metric.value(day))
                        )
                        .foregroundStyle(.tint)
                    }
                    .frame(height: 170)
                }
            }

            Section("Days") {
                ForEach(days) { day in
                    NavigationLink { DayDetailView(day: day) } label: { dayRow(day) }
                        .accessibilityIdentifier("history.day")
                }
            }
        }
        .navigationTitle("History")
    }

    private func dayRow(_ day: DayScore) -> some View {
        let potential = Decimal(day.potentialZMinutes) * day.perMinuteRate
        let headline = FramingPresenter.headline(kept: day.keptAmount, slipped: day.slippedAmount,
                                                 potential: potential, variant: day.variant)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.logicalDate.formatted(.dateTime.weekday().month().day()))
                    .font(.headline)
                Text("\(day.slipCount) slips · \(day.deepWorkMinutes)m focus")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(headline.amountFormatted).font(.subheadline.monospacedDigit())
                if let mood = day.mood {
                    Text("mood \(mood)").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// The metric a `HistoryView` trend chart shows. `mood`/`slips` cover the trends
/// the spec calls out watching together.
enum TrendMetric: String, CaseIterable, Identifiable {
    case kept, deepWork, slips, mood
    var id: String { rawValue }

    var title: String {
        switch self {
        case .kept: return "Kept ₹"
        case .deepWork: return "Focus"
        case .slips: return "Slips"
        case .mood: return "Mood"
        }
    }

    func value(_ day: DayScore) -> Double {
        switch self {
        case .kept: return NSDecimalNumber(decimal: day.keptAmount).doubleValue
        case .deepWork: return Double(day.deepWorkMinutes)
        case .slips: return Double(day.slipCount)
        case .mood: return Double(day.mood ?? 0)
        }
    }
}
