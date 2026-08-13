import SwiftUI
import SwiftData

@main
struct HabitAppApp: App {
    let container: ModelContainer

    init() {
        let models: [any PersistentModel.Type] = [Goal.self, Habit.self, HabitLog.self,
                                                   DayScore.self, AppConfig.self]
        do {
            #if DEBUG
            // UI tests launch with "-uitesting" → clean, in-memory store every run.
            if ProcessInfo.processInfo.arguments.contains("-uitesting") {
                let schema = Schema(models)
                container = try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            } else {
                container = try ModelContainer(for: Goal.self, Habit.self, HabitLog.self,
                                               DayScore.self, AppConfig.self)
            }
            #else
            container = try ModelContainer(for: Goal.self, Habit.self, HabitLog.self,
                                           DayScore.self, AppConfig.self)
            #endif
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        HabitSeeder.seedIfNeeded(container.mainContext)
        #if DEBUG
        DebugSeed.seedIfNeeded(container.mainContext)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
