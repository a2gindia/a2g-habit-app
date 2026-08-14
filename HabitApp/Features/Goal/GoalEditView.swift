import SwiftUI
import SwiftData

/// Edit the active goal after onboarding. Presented as a sheet from the dashboard.
/// Changing the goal changes *today's* rate going forward; past `DayScore`s keep
/// their snapshotted rate, so history stays attributable.
struct GoalEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let goal: Goal

    @State private var draft: GoalDraft

    init(goal: Goal) {
        self.goal = goal
        _draft = State(initialValue: GoalDraft(goal: goal))
    }

    var body: some View {
        NavigationStack {
            Form {
                GoalFormFields(draft: $draft)
            }
            .navigationTitle("Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(draft.rates == nil)
                        .accessibilityIdentifier("goal.save")
                }
            }
        }
    }

    private func save() {
        goal.targetAmount = draft.targetAmount
        goal.horizonYears = draft.horizonYears
        goal.denominator = draft.denominator
        try? context.save()
        dismiss()
    }
}
