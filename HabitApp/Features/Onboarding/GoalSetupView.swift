import SwiftUI
import SwiftData

/// First-run goal configuration. Uses the shared `GoalFormFields`; on Start it
/// creates the active Goal (and ensures the config row), which flips RootView to
/// the dashboard via @Query.
struct GoalSetupView: View {
    @Environment(\.modelContext) private var context
    var onDone: () -> Void

    @State private var draft = GoalDraft()

    var body: some View {
        Form {
            GoalFormFields(draft: $draft)
        }
        .navigationTitle("Your goal")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Start", action: save)
                    .disabled(draft.rates == nil)
                    .accessibilityIdentifier("goal.start")
            }
        }
    }

    private func save() {
        let goal = Goal(targetAmount: draft.targetAmount,
                        horizonYears: draft.horizonYears,
                        denominator: draft.denominator)
        context.insert(goal)
        _ = AppConfig.current(in: context)   // ensure the single config row exists
        try? context.save()                  // persist explicitly, like every other mutation site
        onDone()
    }
}
