import Foundation

/// Validation rules from the web app, centralised so both onboarding and
/// settings forms enforce the same constraints.
public enum CalculatorInput {
    /// Maximum integer digits allowed before the decimal point.
    public static let maxIntegerDigits = 8
    /// Maximum digits allowed after the decimal point.
    public static let maxFractionDigits = 2

    /// Apply a single keypad press (`"0"`–`"9"`, `"."`, `"backspace"`) to
    /// the current input string and return the new value. Mirrors the
    /// `keyPress` function in the original web app, including the digit /
    /// decimal limits.
    public static func apply(key: String, to current: String) -> String {
        if key == "backspace" {
            return current.count > 1 ? String(current.dropLast()) : "0"
        }
        if key == "." {
            return current.contains(".") ? current : current + "."
        }
        // numeric digit
        if current.contains(".") {
            let parts = current.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2, parts[1].count >= maxFractionDigits { return current }
        } else {
            // strip leading zero from integer part length comparison
            let stripped = current.hasPrefix("0") ? String(current.dropFirst()) : current
            if stripped.count >= maxIntegerDigits { return current }
        }
        if current == "0" { return key }
        return current + key
    }

    /// Parse the keypad input into a Double, returning 0 for invalid input.
    public static func amount(from input: String) -> Double {
        Double(input) ?? 0
    }
}
