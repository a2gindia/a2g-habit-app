import SwiftUI

/// The honesty requirement, stated plainly before the user ever sees a per-hour
/// number: this is a pacing metaphor, not a forecast. If the app pretends the
/// number predicts a bank balance, the user stops trusting every other number.
struct HonestyView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 0)

            Image(systemName: "hourglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tint)

            Text("Time is the number.")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                Text("This app turns your goal into a rate — what an hour, a minute, a second is *worth* against it.")
                Text("It's a **pacing metaphor, not a forecast.** Wealth doesn't accrue in a straight line per hour. The number exists to make time feel concrete — not to predict your bank balance.")
                Text("Everything here is a simulated ledger. No real money moves.")
                    .foregroundStyle(.secondary)
            }
            .font(.body)

            Spacer()

            Button(action: onContinue) {
                Text("I understand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("honesty.continue")
        }
        .padding(24)
        .multilineTextAlignment(.leading)
    }
}

#Preview {
    HonestyView(onContinue: {})
}
