import Foundation
import SwiftData

@Model
final class EntryRecord {
    @Attribute(.unique) var id: String
    var name: String
    var amount: Double
    var minutes: Double
    var decisionRaw: String
    var notes: String
    var category: String
    var timestamp: Date
    var owner: UserAccount?

    init(id: String = UUID().uuidString,
         name: String,
         amount: Double,
         minutes: Double,
         decision: Decision,
         notes: String = "",
         category: String,
         timestamp: Date = Date(),
         owner: UserAccount? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.minutes = minutes
        self.decisionRaw = decision.rawValue
        self.notes = notes
        self.category = category
        self.timestamp = timestamp
        self.owner = owner
    }

    var decision: Decision {
        get { Decision(rawValue: decisionRaw) ?? Decision.normalise(decisionRaw) ?? .skip }
        set { decisionRaw = newValue.rawValue }
    }

    var isWatchlist: Bool { decision == .watchlist }

    var dto: EntryDTO {
        EntryDTO(id: id, amount: amount, minutes: minutes, decision: decision,
                 name: name, category: category, timestamp: timestamp)
    }

    /// Return the rate that was effectively used for this entry. Falls back
    /// to the supplied `currentRate` when the entry has no recorded amount.
    func inferredRate(fallback currentRate: Double) -> Double {
        if amount > 0, minutes > 0 { return amount / minutes }
        return currentRate
    }
}
