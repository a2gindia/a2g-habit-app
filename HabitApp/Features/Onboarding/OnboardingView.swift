import SwiftUI

/// First-run flow: state the honesty requirement, then configure the goal.
struct OnboardingView: View {
    @State private var showGoalSetup = false

    var body: some View {
        NavigationStack {
            HonestyView(onContinue: { showGoalSetup = true })
                .navigationDestination(isPresented: $showGoalSetup) {
                    // onDone is a no-op: inserting the active Goal flips RootView
                    // to the dashboard automatically via @Query.
                    GoalSetupView(onDone: {})
                }
        }
    }
}
