import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @State private var detail: EntryRecord?

    var body: some View {
        NavigationStack {
            Group {
                if let user = session.currentUser, !user.watchlistEntries.isEmpty {
                    list(entries: user.watchlistEntries)
                } else {
                    ContentUnavailableView {
                        Label("Nothing on your watchlist", systemImage: "eye")
                    } description: {
                        Text("Send something here from the calculator when you want to think about it later.")
                    }
                }
            }
            .navigationTitle("Watchlist")
            .sheet(item: $detail) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private func list(entries: [EntryRecord]) -> some View {
        List(entries) { entry in
            EntryRow(entry: entry)
                .contentShape(.rect)
                .onTapGesture { detail = entry }
                .swipeActions(edge: .leading) {
                    Button {
                        quickMove(entry, to: .buy)
                    } label: { Label("Buy", systemImage: "checkmark.circle.fill") }
                        .tint(.green)
                    Button {
                        quickMove(entry, to: .skip)
                    } label: { Label("Skip", systemImage: "xmark.circle.fill") }
                        .tint(.red)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        forget(entry)
                    } label: { Label("Forget", systemImage: "trash") }
                }
        }
        .listStyle(.insetGrouped)
    }

    private func quickMove(_ entry: EntryRecord, to decision: Decision) {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        try? store.update(entry,
                          name: entry.name,
                          amount: entry.amount,
                          category: entry.category,
                          decision: decision,
                          notes: entry.notes)
    }

    private func forget(_ entry: EntryRecord) {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        try? store.delete(entry)
    }
}
