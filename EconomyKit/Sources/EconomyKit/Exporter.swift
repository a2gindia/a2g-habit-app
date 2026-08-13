import Foundation

/// Exports day-record history to a local file you can pull off-device and
/// analyse — the "metrics recording to a local store you can export" the week-1
/// definition of done requires. No networking; the caller writes the string to
/// disk / a share sheet.
public enum Exporter {

    /// Stable column order. ISO-8601 dates, full-precision decimals, empty cell
    /// for an unrecorded mood.
    public static let csvHeader = [
        "logicalDate", "variant", "perMinuteRate", "potentialZMinutes",
        "grossEarnedMinutes", "streakMultiplier", "honestyBonusMinutes",
        "slipMinutes", "deepWorkMinutes", "slipCount",
        "keptAmount", "slippedAmount", "mood"
    ]

    public static func csv(_ records: [DayRecord]) -> String {
        let iso = ISO8601DateFormatter()
        var lines = [csvHeader.joined(separator: ",")]
        for r in records.sorted(by: { $0.logicalDate < $1.logicalDate }) {
            let cells = [
                iso.string(from: r.logicalDate),
                r.variant.rawValue,
                "\(r.perMinuteRate)",
                "\(r.potentialZMinutes)",
                "\(r.grossEarnedMinutes)",
                "\(r.streakMultiplier)",
                "\(r.honestyBonusMinutes)",
                "\(r.slipMinutes)",
                "\(r.deepWorkMinutes)",
                "\(r.slipCount)",
                "\(r.keptAmount)",
                "\(r.slippedAmount)",
                r.mood.map(String.init) ?? ""
            ]
            lines.append(cells.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    public static func json(_ records: [DayRecord]) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let sorted = records.sorted(by: { $0.logicalDate < $1.logicalDate })
        let data = try encoder.encode(sorted)
        return String(decoding: data, as: UTF8.self)
    }

    /// RFC-4180 minimal escaping: quote only when the cell contains a comma,
    /// quote, or newline. Our numeric/enum/date cells never do, but stay safe.
    private static func escape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
