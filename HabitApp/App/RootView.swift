import SwiftUI
import SwiftData

/// Branches on whether a goal is configured: first run → onboarding, otherwise
/// the dashboard. Inserting an active `Goal` flips this automatically via @Query.
struct RootView: View {
    @Query(filter: #Predicate<Goal> { $0.isActive }, sort: \Goal.startDate, order: .reverse)
    private var activeGoals: [Goal]

    var body: some View {
        if let goal = activeGoals.first {
            MainTabView(goal: goal)
        } else {
            OnboardingView()
        }
    }
}
