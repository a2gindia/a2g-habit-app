import SwiftUI
import EconomyKit

/// Full breakdown of one logical day, read from its snapshotted `DayScore`.
struct DayDetailView: View {
    let day: DayScore

    private var potential: Decimal { Decimal(day.potentialZMinutes) * day.perMinuteRate }
    private var headline: FramingHeadline {
        FramingPresenter.headline(kept: day.keptAmount, slipped: day.slippedAmount,
                                  potential: potential, variant: day.variant)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Text(headline.amountFormatted)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .accessibilityIdentifier("detail.amount")
                    Text(headline.caption).font(.subheadline).foregroundStyle(.secondary)
                    Text(headline.subtext).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Breakdown") {
                row("Earned (before streak)", "\(day.grossEarnedMinutes) min")
                row("Streak multiplier", String(format: "%.1f×", day.streakMultiplier))
                row("Honesty bonus", "+\(day.honestyBonusMinutes) min")
                row("Slips", "−\(day.slipMinutes) min")
                row("Kept", MoneyFormatting.inr(day.keptAmount))
                row("Let slip", MoneyFormatting.inr(day.slippedAmount))
            }

            Section("Day") {
                row("Deep work", "\(day.deepWorkMinutes) min")
                row("Slip count", "\(day.slipCount)")
                row("Mood", day.mood.map { "\($0)/5" } ?? "—")
                row("Framing", day.variant.rawValue.capitalized)
                row("Rate", "\(MoneyFormatting.inr(day.perMinuteRate, fractionDigits: 2))/min")
            }
        }
        .navigationTitle(day.logicalDate.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
    }
}
