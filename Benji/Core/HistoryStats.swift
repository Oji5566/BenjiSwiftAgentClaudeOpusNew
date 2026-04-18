import Foundation

/// Aggregated stats shown at the top of the History tab.
public struct HistoryStats: Equatable, Sendable {
    public var total: Int
    public var totalAmount: Double
    public var boughtCount: Int
    public var boughtAmount: Double
    public var boughtMinutes: Double
    public var skippedCount: Int
    public var skippedAmount: Double
    public var skippedMinutes: Double

    /// Bought share rounded to a whole percent (0–100).
    public var boughtPercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(boughtCount) / Double(total) * 100).rounded())
    }
    /// Skipped share — always `100 - boughtPercent` to avoid double-rounding,
    /// matching the web app.
    public var skippedPercent: Int { max(0, 100 - boughtPercent) }

    public init(entries: [EntryDTO]) {
        self.total = entries.count
        self.totalAmount = entries.reduce(0) { $0 + $1.amount }
        let bought  = entries.filter { $0.decision == .buy }
        let skipped = entries.filter { $0.decision == .skip }
        self.boughtCount    = bought.count
        self.boughtAmount   = bought.reduce(0) { $0 + $1.amount }
        self.boughtMinutes  = bought.reduce(0) { $0 + $1.minutes }
        self.skippedCount   = skipped.count
        self.skippedAmount  = skipped.reduce(0) { $0 + $1.amount }
        self.skippedMinutes = skipped.reduce(0) { $0 + $1.minutes }
    }
}
