import SwiftUI

/// The main shell once a goal exists: the time-value dashboard and the log.
struct MainTabView: View {
    let goal: Goal
    @State private var selection: Int

    init(goal: Goal) {
        self.goal = goal
        #if DEBUG
        switch ProcessInfo.processInfo.environment["DEMO_TAB"] {
        case "log":      _selection = State(initialValue: 1)
        case "insights": _selection = State(initialValue: 2)
        default:         _selection = State(initialValue: 0)
        }
        #else
        _selection = State(initialValue: 0)
        #endif
    }

    var body: some View {
        TabView(selection: $selection) {
            DashboardView(goal: goal)
                .tag(0)
                .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }
            LogView(goal: goal)
                .tag(1)
                .tabItem { Label("Log", systemImage: "square.and.pencil") }
            InsightsView()
                .tag(2)
                .tabItem { Label("Insights", systemImage: "chart.bar") }
        }
    }
}
