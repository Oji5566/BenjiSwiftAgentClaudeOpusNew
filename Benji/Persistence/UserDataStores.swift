import Foundation
import SwiftData

/// Convenience methods on `UserAccount` that operate against a
/// `ModelContext`. Keeps view code free of persistence boilerplate.
extension UserAccount {

    var orderedCategories: [CategoryRecord] {
        categories.sorted { $0.sortIndex < $1.sortIndex }
    }

    var historyEntries: [EntryRecord] {
        entries.filter { $0.decision != .watchlist }
              .sorted { $0.timestamp > $1.timestamp }
    }

    var watchlistEntries: [EntryRecord] {
        entries.filter { $0.decision == .watchlist }
              .sorted { $0.timestamp > $1.timestamp }
    }

    var earningSettings: EarningSettings {
        settings?.asEarningSettings ?? EarningSettings()
    }

    var earningPerMinute: Double {
        EarningRateCalculator.perMinute(earningSettings)
    }

    var onboardingComplete: Bool { settings?.onboardingComplete ?? false }
}

struct EntryStore {
    let context: ModelContext
    let user: UserAccount

    func add(name: String, amount: Double, decision: Decision, category: String, notes: String = "") throws {
        let rate = user.earningPerMinute
        let minutes = EarningRateCalculator.minutes(forAmount: amount, rate: rate)
        let entry = EntryRecord(
            name: name.isEmpty ? "Unnamed" : name,
            amount: amount,
            minutes: minutes,
            decision: decision,
            notes: notes,
            category: category,
            owner: user
        )
        user.entries.append(entry)
        context.insert(entry)
        try context.save()
    }

    func update(_ entry: EntryRecord, name: String, amount: Double, category: String, decision: Decision, notes: String) throws {
        let rate = entry.inferredRate(fallback: user.earningPerMinute)
        entry.name = name.isEmpty ? "Unnamed" : name
        entry.amount = amount
        entry.minutes = EarningRateCalculator.minutes(forAmount: amount, rate: rate)
        entry.category = category
        entry.decision = decision
        entry.notes = notes
        try context.save()
    }

    func delete(_ entry: EntryRecord) throws {
        context.delete(entry)
        try context.save()
    }

    func clearAll() throws {
        for entry in user.entries { context.delete(entry) }
        try context.save()
    }
}

struct CategoryStore {
    let context: ModelContext
    let user: UserAccount

    func add(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let next = (user.categories.map { $0.sortIndex }.max() ?? -1) + 1
        let cat = CategoryRecord(name: trimmed, sortIndex: next, owner: user)
        user.categories.append(cat)
        context.insert(cat)
        try context.save()
    }

    func rename(_ category: CategoryRecord, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let oldName = category.name
        category.name = trimmed
        // Update all entries that referenced the old display name
        for e in user.entries where e.category == oldName {
            e.category = trimmed
        }
        try context.save()
    }

    func delete(_ category: CategoryRecord) throws {
        context.delete(category)
        try context.save()
        renumber()
    }

    /// Move category at `source` to `destination` index. Mirrors SwiftUI's
    /// `onMove` index semantics.
    func move(from source: IndexSet, to destination: Int) throws {
        var ordered = user.orderedCategories
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, c) in ordered.enumerated() { c.sortIndex = i }
        try context.save()
    }

    private func renumber() {
        for (i, c) in user.orderedCategories.enumerated() { c.sortIndex = i }
        try? context.save()
    }
}
