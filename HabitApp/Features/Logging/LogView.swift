import SwiftUI
import SwiftData
import EconomyKit

/// Logging is deliberately flat and factual. No "you failed", no red, no shame
/// animation — log it, move on. A slip logged here never deducts on its own; the
/// behaviour is scored at roll-up, and honesty is rewarded, never punished.
struct LogView: View {
    let goal: Goal
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var configs: [AppConfig]

    @State private var durationHabit: Habit?

    private var lightsOutHour: Int { configs.first?.lightsOutHour ?? Tuning.defaultLightsOutHour }
    private var todayStart: Date { DayBoundary(lightsOutHour: lightsOutHour).logicalDayStart(for: .now) }

    private var buildHabits: [Habit] { habits.filter { $0.kind == .build } }
    private var breakHabits: [Habit] { habits.filter { $0.kind == .breakHabit } }

    var body: some View {
        NavigationStack {
            List {
                Section("Build") {
                    ForEach(buildHabits) { buildRow($0) }
                }
                Section("When it slips") {
                    ForEach(breakHabits) { breakRow($0) }
                }
            }
            .navigationTitle("Log")
            .sheet(item: $durationHabit) { habit in
                DurationEntrySheet(habit: habit) { minutes in
                    log(habit, durationMinutes: minutes)
                }
            }
        }
    }

    // MARK: rows

    private func buildRow(_ habit: Habit) -> some View {
        let count = todayCount(habit)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.label)
                if count > 0 {
                    Text(habit.usesLoggedDuration ? "\(todayMinutes(habit)) min today" : "done \(count)×")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                if habit.usesLoggedDuration { durationHabit = habit }
                else { log(habit) }
            } label: {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("log.\(slug(habit.name))")
        }
    }

    private func breakRow(_ habit: Habit) -> some View {
        let count = todayCount(habit)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.label)
                if count > 0 {
                    Text("\(count)× today").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Log") { log(habit) }
                .buttonStyle(.bordered)
                .tint(.secondary)                       // neutral, never red
                .accessibilityIdentifier("log.\(slug(habit.name))")
        }
    }

    // MARK: today helpers

    private func todaysLogs(_ habit: Habit) -> [HabitLog] {
        habit.logs.filter { $0.timestamp >= todayStart }
    }
    private func todayCount(_ habit: Habit) -> Int { todaysLogs(habit).count }
    private func todayMinutes(_ habit: Habit) -> Int {
        todaysLogs(habit).reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    // MARK: logging

    private func log(_ habit: Habit, durationMinutes: Int? = nil) {
        context.insert(HabitLog(habit: habit, durationMinutes: durationMinutes))
        try? context.save()
        // Roll today's DayScore forward at the source of the change, so the
        // dashboard (which observes DayScore) reflects it without polling all logs.
        if let config = configs.first {
            DayScoreStore.upsertToday(goal: goal, config: config, habits: habits, context: context)
        }
    }

    private func slug(_ s: String) -> String {
        s.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}

/// Minutes entry for duration-based build habits (deep work).
private struct DurationEntrySheet: View {
    let habit: Habit
    var onLog: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var minutes = 50

    var body: some View {
        NavigationStack {
            Form {
                Stepper("\(minutes) min", value: $minutes, in: 5...480, step: 5)
                HStack {
                    ForEach([25, 50, 90], id: \.self) { m in
                        Button("\(m) min") { minutes = m }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(habit.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { onLog(minutes); dismiss() }
                        .accessibilityIdentifier("duration.log")
                }
            }
        }
        .presentationDetents([.medium])
    }
}
