import SwiftUI
import SwiftData
import EconomyKit

/// Edits the two user-facing app settings: the lights-out day boundary and the
/// daily focus target that defines the potential `Z`. (The framing A/B anchor is
/// deliberately not exposed — shifting it mid-experiment would corrupt the data.)
struct ConfigEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let config: AppConfig
    let goal: Goal

    @State private var lightsOutHour: Int
    @State private var targetMinutes: Int

    init(config: AppConfig, goal: Goal) {
        self.config = config
        self.goal = goal
        _lightsOutHour = State(initialValue: config.lightsOutHour)
        _targetMinutes = State(initialValue: config.dailyPotentialTargetMinutes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Day boundary") {
                    Stepper("Lights-out: \(Self.hour(lightsOutHour))", value: $lightsOutHour, in: 0...23)
                        .accessibilityIdentifier("config.lightsOut")
                    Text("A slip before this hour counts toward the previous day.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Daily target") {
                    Stepper("Focus target: \(Self.duration(targetMinutes))",
                            value: $targetMinutes, in: 30...720, step: 15)
                        .accessibilityIdentifier("config.target")
                    if let perMinute = goal.rates?.perMinute {
                        LabeledContent("Daily potential",
                                       value: MoneyFormatting.inr(Decimal(targetMinutes) * perMinute))
                    }
                    Text("The ceiling you're measured against each day.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).accessibilityIdentifier("config.save")
                }
            }
        }
    }

    private func save() {
        config.lightsOutHour = lightsOutHour
        config.dailyPotentialTargetMinutes = targetMinutes
        try? context.save()
        dismiss()
    }

    // MARK: formatting

    static func hour(_ h: Int) -> String {
        let ampm = h < 12 ? "AM" : "PM"
        let h12 = h % 12 == 0 ? 12 : h % 12
        return "\(h12):00 \(ampm)"
    }
    static func duration(_ m: Int) -> String {
        let h = m / 60, min = m % 60
        if h > 0 && min > 0 { return "\(h)h \(min)m" }
        if h > 0 { return "\(h)h" }
        return "\(min)m"
    }
}
