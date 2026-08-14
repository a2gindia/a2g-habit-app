import SwiftUI
import SwiftData
import EconomyKit

/// Manage habits: add, edit, reorder, and archive. Archiving hides a habit from
/// logging while keeping its history; deleting (only offered on already-archived
/// habits) cascades the logs away.
struct HabitListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var adding: AddContext?
    @State private var editing: Habit?

    private struct AddContext: Identifiable { let id = UUID(); let kind: HabitKind }

    private var build: [Habit] { habits.filter { $0.kind == .build && !$0.isArchived } }
    private var breaks: [Habit] { habits.filter { $0.kind == .breakHabit && !$0.isArchived } }
    private var archived: [Habit] { habits.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            List {
                Section("Build") {
                    ForEach(build) { activeRow($0) }
                        .onMove { move(.build, $0, $1) }
                }
                Section("When it slips") {
                    ForEach(breaks) { activeRow($0) }
                        .onMove { move(.breakHabit, $0, $1) }
                }
                if !archived.isEmpty {
                    Section("Archived") {
                        ForEach(archived) { archivedRow($0) }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("habits.done")
                }
                ToolbarItem(placement: .primaryAction) { EditButton() }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("New build habit") { adding = AddContext(kind: .build) }
                        Button("New break habit") { adding = AddContext(kind: .breakHabit) }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("habits.add")
                }
            }
            .sheet(item: $adding) { HabitEditView(newKind: $0.kind) }
            .sheet(item: $editing) { HabitEditView(habit: $0) }
        }
    }

    // MARK: rows

    private func activeRow(_ habit: Habit) -> some View {
        Button { editing = habit } label: {
            HStack {
                Text(habit.label).foregroundStyle(.primary)
                Spacer()
                Text(summary(habit)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button { archive(habit, true) } label: { Label("Archive", systemImage: "archivebox") }
                .tint(.orange)
        }
    }

    private func archivedRow(_ habit: Habit) -> some View {
        HStack {
            Text(habit.label).foregroundStyle(.secondary)
            Spacer()
            Text("archived").font(.caption).foregroundStyle(.tertiary)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { delete(habit) } label: { Label("Delete", systemImage: "trash") }
            Button { archive(habit, false) } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
                .tint(.blue)
        }
    }

    private func summary(_ habit: Habit) -> String {
        switch habit.kind {
        case .build:
            if habit.usesLoggedDuration { return "logged time" }
            let cap = habit.targetPerDay.map { " · up to \($0)×" } ?? ""
            return "+\(habit.rewardMinutes)m\(cap)"
        case .breakHabit:
            return "−\(habit.costMinutes)m"
        }
    }

    // MARK: mutations

    private func move(_ kind: HabitKind, _ from: IndexSet, _ to: Int) {
        var items = kind == .build ? build : breaks
        items.move(fromOffsets: from, toOffset: to)
        let base = kind == .build ? 0 : 1_000   // keep the two kinds' ranges apart
        for (i, habit) in items.enumerated() { habit.sortOrder = base + i }
        try? context.save()
    }

    private func archive(_ habit: Habit, _ value: Bool) {
        habit.isArchived = value
        try? context.save()
    }

    private func delete(_ habit: Habit) {
        context.delete(habit)
        try? context.save()
    }
}
