import Foundation

/// Formatting helpers shared between UI and tests.
public enum Formatters {

    /// Money formatter — fixed two decimal places, prefixed with `$`.
    /// Matches the web app's `formatCurrency`. Locale-independent so it
    /// behaves identically in production, previews, and CI.
    public static func currency(_ amount: Double) -> String {
        let rounded = (amount * 100).rounded() / 100
        let absStr = String(format: "%.2f", abs(rounded))
        let parts = absStr.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts[0])
        let fracPart = parts.count > 1 ? String(parts[1]) : "00"
        // Insert thousands separators manually so we don't depend on
        // NumberFormatter (which has Foundation gaps on non-Apple platforms).
        var grouped = ""
        for (i, ch) in intPart.reversed().enumerated() {
            if i > 0, i % 3 == 0 { grouped = "," + grouped }
            grouped.insert(ch, at: grouped.startIndex)
        }
        let sign = rounded < 0 ? "-" : ""
        return "\(sign)$\(grouped).\(fracPart)"
    }

    /// Render a quantity of minutes into a human-friendly time string.
    /// Matches the web app's `formatMinutes` exactly:
    ///
    /// * `≤ 0` -> "0 mins"
    /// * `< 1`  -> seconds ("45 secs")
    /// * `< 60` -> minutes ("12 mins")
    /// * else   -> "h hrs m mins"
    public static func minutes(_ minutes: Double) -> String {
        if minutes <= 0 { return "0 mins" }
        if minutes < 1 {
            return "\(Int((minutes * 60).rounded(.toNearestOrAwayFromZero))) secs"
        }
        if minutes < 60 {
            let m = Int(minutes.rounded())
            return "\(m) min" + (m == 1 ? "" : "s")
        }
        let h = Int(minutes / 60)
        let m = Int(minutes.truncatingRemainder(dividingBy: 60).rounded())
        let hStr = "\(h) hr" + (h == 1 ? "" : "s")
        if m == 0 { return hStr }
        return "\(hStr) \(m) min" + (m == 1 ? "" : "s")
    }

    /// Per-minute rate display, e.g. `$0.1667 / min`.
    public static func ratePerMinute(_ rate: Double) -> String {
        String(format: "$%.4f / min", rate)
    }
}
