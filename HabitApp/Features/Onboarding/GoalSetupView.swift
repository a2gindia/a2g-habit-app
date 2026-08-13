import SwiftUI
import SwiftData
import EconomyKit

/// Configure the goal: target amount, horizon, and the denominator — the setting
/// that reshapes the whole app's emotional weight. Live-previews the resulting
/// per-hour rate so the choice is concrete.
struct GoalSetupView: View {
    @Environment(\.modelContext) private var context
    var onDone: () -> Void

    @State private var targetAmount: Decimal = 1_000_000_000   // 100 cr
    @State private var horizonYears: Double = 5
    @State private var kind: DenominatorKind = .calendarHours
    @State private var workPerDay: Double = 8
    @State private var workDaysPerWeek: Int = 5
    @State private var customHours: Double = 10_000

    private enum DenominatorKind: String, CaseIterable, Identifiable {
        case calendarHours = "Calendar"
        case workingHours = "Working"
        case custom = "Custom"
        var id: String { rawValue }
    }

    private var denominator: Denominator {
        switch kind {
        case .calendarHours: return .calendarHours
        case .workingHours:  return .workingHours(perDay: workPerDay, daysPerWeek: workDaysPerWeek)
        case .custom:        return .custom(totalHours: customHours)
        }
    }

    private var previewRates: Rates? {
        TimeValueEngine.rates(for: GoalParameters(targetAmount: targetAmount,
                                                  horizonYears: horizonYears,
                                                  denominator: denominator))
    }

    var body: some View {
        Form {
            Section("Target") {
                LabeledContent("Amount") {
                    TextField("Amount", value: $targetAmount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                VStack(alignment: .leading) {
                    Text("Horizon: \(horizonYears, specifier: "%.1f") years")
                    Slider(value: $horizonYears, in: 0.5...40, step: 0.5)
                }
            }

            Section("Denominator") {
                Picker("Hours counted", selection: $kind) {
                    ForEach(DenominatorKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch kind {
                case .calendarHours:
                    Text("Every hour of the horizon counts.")
                        .font(.footnote).foregroundStyle(.secondary)
                case .workingHours:
                    Stepper("Hours/day: \(workPerDay, specifier: "%.0f")", value: $workPerDay, in: 1...16, step: 1)
                    Stepper("Days/week: \(workDaysPerWeek)", value: $workDaysPerWeek, in: 1...7)
                case .custom:
                    Stepper("Total hours: \(customHours, specifier: "%.0f")", value: $customHours, in: 100...200_000, step: 100)
                    Text("Ignores the horizon above.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("At this pace") {
                if let r = previewRates {
                    LabeledContent("Per hour", value: MoneyFormatting.inr(r.perHour))
                    LabeledContent("Per minute", value: MoneyFormatting.inr(r.perMinute))
                    LabeledContent("Per second", value: MoneyFormatting.inr(r.perSecond, fractionDigits: 2))
                } else {
                    Text("Enter a target and horizon to see the rate.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Your goal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Start", action: save)
                    .disabled(previewRates == nil)
                    .accessibilityIdentifier("goal.start")
            }
        }
    }

    private func save() {
        let goal = Goal(targetAmount: targetAmount, horizonYears: horizonYears, denominator: denominator)
        context.insert(goal)
        _ = AppConfig.current(in: context)   // ensure the single config row exists
        try? context.save()                  // persist explicitly, like every other mutation site
        onDone()
    }
}
