import SwiftUI

/// A plain-language "how it works" guide for the app's game-like loop: how to
/// read the Today number, how to track, and how to analyse.
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Time is the number.").font(.title3.bold())
                        Text("Your goal becomes a rate — what an hour, a minute, a second is worth against it. It's a pacing metaphor, not a forecast, and everything here is a simulated ledger. No real money moves.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Use · the Today tab") {
                    row("chart.line.uptrend.xyaxis", "Today's headline",
                        "The big number is your day. On “gain” weeks it's what you kept toward your goal; on “loss” weeks it's what you let slip — same math, two lenses. It switches each week.")
                    row("clock", "Your rate",
                        "The card shows what an hour, a minute, and a second are worth toward your goal.")
                    row("face.smiling", "Mood",
                        "Tap 1–5 once a day to record how it felt.")
                }

                Section("Track · the Log tab") {
                    row("plus.circle.fill", "Build habits",
                        "Things you want to do more of. Tap ＋ when you do one, − to undo a mistake. “Deep work” logs the minutes you focused.")
                    row("minus.circle", "When it slips",
                        "Things you want less of. Tap ＋ when it happens — logging is neutral and never shames you. Being honest is rewarded, not punished; − undoes a mis-tap.")
                    row("slider.horizontal.3", "Manage habits",
                        "The slider icon lets you add, edit, reorder, or archive habits.")
                }

                Section("Analyse · the Insights tab") {
                    row("chart.bar", "Metrics",
                        "How often you log, your focus minutes, slips, and average mood.")
                    row("calendar", "History & trends",
                        "“Day-by-day history” charts any metric over time and opens each day's full breakdown.")
                    row("square.and.arrow.up", "Export",
                        "Save your whole history as CSV or JSON to analyse anywhere.")
                }

                Section("How scoring works") {
                    row("bolt.fill", "Earning",
                        "Deep-work minutes and completed build habits earn time-value. A streak of logging days boosts earnings, up to 1.5×.")
                    row("arrow.down.circle", "Slips",
                        "A slip costs time-value, but an honesty bonus softens an honest log — and your day never drops below zero.")
                }
            }
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("guide.done")
                }
            }
        }
    }

    private func row(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 26).foregroundStyle(.tint).padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
