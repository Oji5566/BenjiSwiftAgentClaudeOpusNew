import SwiftUI
import SwiftData

/// Shared editor used by both the History and Watchlist tabs to view,
/// edit, move, and delete a single entry.
struct EntryDetailView: View {
    @Bindable var entry: EntryRecord

    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var category: String = ""
    @State private var decision: Decision = .buy
    @State private var notes: String = ""
    @State private var showDeleteConfirm = false

    private var categories: [String] {
        session.currentUser?.orderedCategories.map(\.name) ?? DefaultCategories.all
    }

    var body: some View {
        NavigationStack {
            Form {
                if entry.isWatchlist {
                    Section("Quick actions") {
                        Button { quickMove(to: .buy) } label: {
                            Label("Move to Bought", systemImage: "checkmark.circle.fill")
                        }
                        Button { quickMove(to: .skip) } label: {
                            Label("Move to Skipped", systemImage: "xmark.circle.fill")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Forget", systemImage: "trash")
                        }
                    }
                }

                Section {
                    LabeledContent("Time", value: Formatters.minutes(entry.minutes))
                    LabeledContent("Tracked", value: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                }

                Section("Name") {
                    TextField("Name", text: $name)
                }

                Section("Amount") {
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $decision) {
                        ForEach(Decision.allCases) { Text($0.verb).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(entry.isWatchlist ? "Forget item" : "Delete entry", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(entry.isWatchlist ? "Watchlist Item" : "Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold() }
            }
            .confirmationDialog("This cannot be undone.",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button(entry.isWatchlist ? "Forget" : "Delete", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear { hydrate() }
        }
    }

    private func hydrate() {
        name = entry.name
        amountText = String(format: "%.2f", entry.amount)
        category = categories.contains(entry.category) ? entry.category : (categories.first ?? "❓ Other")
        decision = entry.decision
        notes = entry.notes
    }

    private func save() {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        let amt = Double(amountText) ?? 0
        try? store.update(entry,
                          name: name.trimmingCharacters(in: .whitespaces),
                          amount: amt,
                          category: category,
                          decision: decision,
                          notes: notes.trimmingCharacters(in: .whitespaces))
        dismiss()
    }

    private func quickMove(to newDecision: Decision) {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        let amt = Double(amountText) ?? entry.amount
        try? store.update(entry,
                          name: name.trimmingCharacters(in: .whitespaces),
                          amount: amt,
                          category: category,
                          decision: newDecision,
                          notes: notes)
        dismiss()
    }

    private func performDelete() {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        try? store.delete(entry)
        dismiss()
    }
}
