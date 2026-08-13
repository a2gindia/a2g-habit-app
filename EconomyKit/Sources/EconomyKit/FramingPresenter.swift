import Foundation

/// The rendered daily headline. `amount` is the single primary number the UI
/// shows big; everything else is copy around the same underlying split.
public struct FramingHeadline: Hashable, Sendable {
    public let variant: FramingVariant
    /// The primary displayed number: `kept` under `.gain`, `slipped` under `.loss`.
    public let amount: Decimal
    public let amountFormatted: String
    /// Full framed sentence, e.g. "Kept ₹18,400 toward your goal today."
    public let headline: String
    /// Short label to sit under a large `amountFormatted`, e.g. "kept toward your goal today".
    public let caption: String
    public let subtext: String
}

/// The ONLY place in the app where `.gain` vs `.loss` branches. Both variants are
/// computed from the same `(kept, slipped, potential)` triple produced by
/// `ScoringEngine`; the variant chooses which number is primary and the words
/// around it — nothing else. This is how "same underlying math, only the copy and
/// the primary number change" is enforced structurally rather than by discipline.
public enum FramingPresenter {

    public static func headline(kept: Decimal,
                                slipped: Decimal,
                                potential: Decimal,
                                variant: FramingVariant) -> FramingHeadline {
        let keptText = MoneyFormatting.inr(kept)
        let slippedText = MoneyFormatting.inr(slipped)
        let potentialText = MoneyFormatting.inr(potential)

        switch variant {
        case .gain:
            return FramingHeadline(
                variant: .gain,
                amount: kept,
                amountFormatted: keptText,
                headline: "Kept \(keptText) toward your goal today.",
                caption: "kept toward your goal today",
                subtext: "of \(potentialText) possible")
        case .loss:
            return FramingHeadline(
                variant: .loss,
                amount: slipped,
                amountFormatted: slippedText,
                headline: "You let \(slippedText) slip today.",
                caption: "let slip today",
                subtext: "\(keptText) kept of \(potentialText)")
        }
    }
}
