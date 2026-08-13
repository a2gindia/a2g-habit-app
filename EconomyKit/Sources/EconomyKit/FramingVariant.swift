import Foundation

/// The A/B framing lens for the daily headline. Both variants render the *same*
/// underlying quantity (see `FramingPresenter`, slice 5) — only the copy and
/// which side of the kept/slipped split is emphasised differ.
public enum FramingVariant: String, Codable, Hashable, Sendable, CaseIterable {
    /// "you kept ₹X of today's potential"
    case gain
    /// "you let ₹Y slip today"
    case loss
}
