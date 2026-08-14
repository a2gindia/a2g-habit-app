import SwiftUI
import SwiftData
import EconomyKit

/// Add a new habit or edit an existing one. Scoring is expressed in minutes;
/// build habits either earn a flat reward (optionally capped per day) or from
/// logged duration (deep-work style), break habits burn a per-slip cost.
struct HabitEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let existing: Habit?
    private let kind: HabitKind

    @State private var name: String
    @State private var displayLabel: String
    @State private var usesLoggedDuration: Bool
    @State private var rewardMinutes: Int
    @State private var hasTarget: Bool
    @State private var targetPerDay: Int
    @State private var costMinutes: Int

    init(habit: Habit) {
        existing = habit
        kind = habit.kind
        _name = State(initialValue: habit.name)
        _displayLabel = State(initialValue: habit.displayLabel ?? "")
        _usesLoggedDuration = State(initialValue: habit.usesLoggedDuration)
        _rewardMinutes = State(initialValue: habit.rewardMinutes == 0 ? 30 : habit.rewardMinutes)
        _hasTarget = State(initialValue: habit.targetPerDay != nil)
        _targetPerDay = State(initialValue: habit.targetPerDay ?? 3)
        _costMinutes = State(initialValue: habit.costMinutes == 0 ? 20 : habit.costMinutes)
    }

    init(newKind: HabitKind) {
        existing = nil
        kind = newKind
        _name = State(initialValue: "")
        _displayLabel = State(initialValue: "")
        _usesLoggedDuration = State(initialValue: false)
        _rewardMinutes = State(initialValue: 30)
        _hasTarget = State(initialValue: false)
        _targetPerDay = State(initialValue: 3)
        _costMinutes = State(initialValue: 20)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $name).accessibilityIdentifier("habit.name")
                    TextField("Display label (optional)", text: $displayLabel)
                }

                if kind == .build {
                    Section("Scoring") {
                        Toggle("Earns from logged time", isOn: $usesLoggedDuration)
                        if !usesLoggedDuration {
                            Stepper("Reward: \(rewardMinutes) min", value: $rewardMinutes, in: 0...480, step: 5)
                            Toggle("Cap completions per day", isOn: $hasTarget)
                            if hasTarget {
                                Stepper("Up to \(targetPerDay)×/day", value: $targetPerDay, in: 1...20)
                            }
                        } else {
                            Text("Each log earns its own minutes (like deep work).")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section("Scoring") {
                        Stepper("Cost: \(costMinutes) min", value: $costMinutes, in: 5...240, step: 5)
                        Text("Kept above the honesty bonus so an honest log still stings less than the behaviour itself.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(existing == nil ? "New habit" : "Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("habit.save")
                }
            }
        }
    }

    private func save() {
        let trimmedLabel = displayLabel.trimmingCharacters(in: .whitespaces)
        let habit = existing ?? {
            let h = Habit(name: name, kind: kind, sortOrder: nextSortOrder())
            context.insert(h)
            return h
        }()
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.displayLabel = trimmedLabel.isEmpty ? nil : trimmedLabel
        if kind == .build {
            habit.usesLoggedDuration = usesLoggedDuration
            habit.rewardMinutes = usesLoggedDuration ? 0 : rewardMinutes
            habit.targetPerDay = (usesLoggedDuration || !hasTarget) ? nil : targetPerDay
            habit.costMinutes = 0
        } else {
            habit.costMinutes = costMinutes
            habit.rewardMinutes = 0
            habit.usesLoggedDuration = false
            habit.targetPerDay = nil
        }
        try? context.save()
        dismiss()
    }

    private func nextSortOrder() -> Int {
        let existing = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        return (existing.map(\.sortOrder).max() ?? -1) + 1
    }
}
