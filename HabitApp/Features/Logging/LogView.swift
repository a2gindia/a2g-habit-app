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

    @State private var managing = false

    private var buildHabits: [Habit] { habits.filter { $0.kind == .build && !$0.isArchived } }
    private var breakHabits: [Habit] { habits.filter { $0.kind == .breakHabit && !$0.isArchived } }

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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { managing = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("log.manage")
                    .accessibilityLabel("Manage habits")
                }
            }
            .sheet(item: $durationHabit) { habit in
                DurationEntrySheet(habit: habit) { minutes in
                    log(habit, durationMinutes: minutes)
                }
            }
            .sheet(isPresented: $managing) {
                HabitListView()
            }
            .onAppear {
                #if DEBUG
                if ProcessInfo.processInfo.environment["DEMO_OPEN_HABITS"] == "1" { managing = true }
                #endif
            }
        }
    }

    // MARK: rows

    private func buildRow(_ habit: Habit) -> some View {
        let count = todayCount(habit)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.label)
                if habit.usesLoggedDuration, count > 0 {
                    Text("\(todayMinutes(habit)) min today")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            logStepper(habit, count: count, addTint: .accentColor) {
                if habit.usesLoggedDuration { durationHabit = habit } else { log(habit) }
            }
        }
    }

    private func breakRow(_ habit: Habit) -> some View {
        let count = todayCount(habit)
        return HStack {
            Text(habit.label)
            Spacer()
            logStepper(habit, count: count, addTint: .secondary) { log(habit) }
        }
    }

    /// A −/count/+ control so a mistaken tap is fixable. `−` removes today's most
    /// recent log for this habit (disabled at 0); `+` runs `add`.
    private func logStepper(_ habit: Habit, count: Int, addTint: Color,
                            add: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Button { removeLastToday(habit) } label: {
                Image(systemName: "minus.circle").font(.title2)
            }
            .buttonStyle(.borderless)
            .tint(.secondary)
            .disabled(count == 0)
            .accessibilityIdentifier("unlog.\(slug(habit.name))")

            Text("\(count)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 20)
                .accessibilityIdentifier("count.\(slug(habit.name))")

            Button(action: add) {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .buttonStyle(.borderless)
            .tint(addTint)
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

    /// Undo: delete today's most recent log for the habit, then re-roll the score.
    private func removeLastToday(_ habit: Habit) {
        guard let last = todaysLogs(habit).max(by: { $0.timestamp < $1.timestamp }) else { return }
        context.delete(last)
        try? context.save()
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
