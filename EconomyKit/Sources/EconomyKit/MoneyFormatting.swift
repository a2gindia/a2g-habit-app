import Foundation

/// INR display formatting with Indian digit grouping (₹22,83,105, not ₹2,283,105)
/// and controlled rounding, so the UI never shows raw float/Decimal artifacts.
public enum MoneyFormatting {

    /// Indian-locale currency string. `fractionDigits` fixes both min and max so
    /// output is stable: large rates at 0 digits, per-second at 2.
    public static func inr(_ value: Decimal, fractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.roundingMode = .halfUp
        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? fallback(number, fractionDigits: fractionDigits)
    }

    /// Convenience for the three headline rates, picking sensible precision:
    /// per-hour/minute at 0 digits, per-second at 2 (it's small enough to matter).
    public static func rate(_ value: Decimal, per unit: RateUnit) -> String {
        inr(value, fractionDigits: unit.fractionDigits) + unit.suffix
    }

    public enum RateUnit {
        case hour, minute, second

        var suffix: String {
            switch self {
            case .hour: return "/h"
            case .minute: return "/min"
            case .second: return "/s"
            }
        }

        var fractionDigits: Int {
            switch self {
            case .hour, .minute: return 0
            case .second: return 2
            }
        }
    }

    private static func fallback(_ number: NSDecimalNumber, fractionDigits: Int) -> String {
        "₹" + number.description
    }
}
