import SwiftUI
import EconomyKit

/// The shared goal form: target, horizon, denominator, and a live per-hour/minute/
/// second preview. Rendered inside a `Form` by both the onboarding setup and the
/// editor, so the two never drift apart.
struct GoalFormFields: View {
    @Binding var draft: GoalDraft

    var body: some View {
        Group {
            Section("Target") {
                LabeledContent("Amount") {
                    TextField("Amount", value: $draft.targetAmount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                VStack(alignment: .leading) {
                    Text("Horizon: \(draft.horizonYears, specifier: "%.1f") years")
                    Slider(value: $draft.horizonYears, in: 0.5...40, step: 0.5)
                }
            }

            Section("Denominator") {
                Picker("Hours counted", selection: $draft.kind) {
                    ForEach(GoalDraft.Kind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch draft.kind {
                case .calendarHours:
                    Text("Every hour of the horizon counts.")
                        .font(.footnote).foregroundStyle(.secondary)
                case .workingHours:
                    Stepper("Hours/day: \(draft.workPerDay, specifier: "%.0f")", value: $draft.workPerDay, in: 1...16, step: 1)
                    Stepper("Days/week: \(draft.workDaysPerWeek)", value: $draft.workDaysPerWeek, in: 1...7)
                case .custom:
                    Stepper("Total hours: \(draft.customHours, specifier: "%.0f")", value: $draft.customHours, in: 100...200_000, step: 100)
                    Text("Ignores the horizon above.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("At this pace") {
                if let r = draft.rates {
                    LabeledContent("Per hour", value: MoneyFormatting.inr(r.perHour))
                    LabeledContent("Per minute", value: MoneyFormatting.inr(r.perMinute))
                    LabeledContent("Per second", value: MoneyFormatting.inr(r.perSecond, fractionDigits: 2))
                } else {
                    Text("Enter a target and horizon to see the rate.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
