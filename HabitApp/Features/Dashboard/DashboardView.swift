import SwiftUI
import SwiftData
import EconomyKit

/// The time-value dashboard: today's framed headline (kept vs slipped, per the
/// active weekly variant), the goal's rates, and a one-tap end-of-day mood.
struct DashboardView: View {
    let goal: Goal
    @Environment(\.modelContext) private var context

    @Query private var configs: [AppConfig]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var dayScores: [DayScore]

    @State private var editingGoal = false

    private var config: AppConfig? { configs.first }
    private var snapshot: DayScoreService.Snapshot? {
        guard let config else { return nil }
        return DayScoreService.snapshot(goal: goal, config: config, habits: habits)
    }
    private func todayScore(for start: Date?) -> DayScore? {
        guard let start else { return nil }
        return dayScores.first { $0.logicalDate == start }
    }

    var body: some View {
        // Compute the day's scoring once per render, not per subview.
        let snap = snapshot
        let today = todayScore(for: snap?.logicalDayStart)
        return NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let rates = goal.rates {
                        if let snap { headlineCard(snap) }
                        rateCard(rates)
                        moodCard(currentMood: today?.mood)
                        Text("A pacing metaphor, not a forecast.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ContentUnavailableView("Goal needs a valid rate",
                            systemImage: "target",
                            description: Text("Set a target and denominator to see your time-value."))
                            .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editingGoal = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("dashboard.editGoal")
                    .accessibilityLabel("Edit goal")
                }
            }
            .sheet(isPresented: $editingGoal) {
                GoalEditView(goal: goal)
            }
        }
        // Logging upserts the DayScore at its source (LogView), which this view
        // observes via @Query dayScores; onAppear is the safety net so today's row
        // exists even before any log.
        .onAppear {
            persistToday()
            #if DEBUG
            if ProcessInfo.processInfo.environment["DEMO_OPEN_GOAL_EDIT"] == "1" { editingGoal = true }
            #endif
        }
    }

    // MARK: headline (gain/loss — the only branch is inside FramingPresenter)

    private func headlineCard(_ snap: DayScoreService.Snapshot) -> some View {
        VStack(spacing: 6) {
            Text(snap.headline.amountFormatted)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .accessibilityIdentifier("headline.amount")
            Text(snap.headline.caption)
                .font(.subheadline).foregroundStyle(.secondary)
            Text(snap.headline.subtext)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func rateCard(_ rates: Rates) -> some View {
        VStack(spacing: 4) {
            Text("Every hour is worth").font(.subheadline).foregroundStyle(.secondary)
            Text(MoneyFormatting.inr(rates.perHour))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .accessibilityIdentifier("dashboard.perHour")
            Divider().padding(.vertical, 6)
            HStack {
                rateStat("per minute", MoneyFormatting.inr(rates.perMinute))
                Spacer()
                rateStat("per second", MoneyFormatting.inr(rates.perSecond, fractionDigits: 2))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    private func rateStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    // MARK: mood

    private func moodCard(currentMood: Int?) -> some View {
        VStack(spacing: 8) {
            Text("How was today?").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { m in
                    let selected = currentMood == m
                    Button { setMood(m) } label: {
                        Text("\(m)")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.15),
                                        in: Circle())
                            .foregroundStyle(selected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("mood.\(m)")
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: persistence

    private func persistToday() {
        guard let config else { return }
        DayScoreStore.upsertToday(goal: goal, config: config, habits: habits, context: context)
    }

    private func setMood(_ m: Int) {
        guard let config else { return }
        let row = DayScoreStore.upsertToday(goal: goal, config: config, habits: habits, context: context)
        row?.mood = m
        try? context.save()
    }
}
