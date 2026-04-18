import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @State private var period: HistoryFilter = .daily
    @State private var detail: EntryRecord?

    var body: some View {
        NavigationStack {
            Group {
                if let user = session.currentUser {
                    let entries = filteredEntries(for: user)
                    if entries.isEmpty {
                        emptyState
                    } else {
                        list(entries: entries)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Range", selection: $period) {
                        ForEach(HistoryFilter.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .sheet(item: $detail) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    private func filteredEntries(for user: UserAccount) -> [EntryRecord] {
        user.historyEntries.filter { EntryFilter.keep(timestamp: $0.timestamp, in: period) }
    }

    private func list(entries: [EntryRecord]) -> some View {
        let stats = HistoryStats(entries: entries.map(\.dto))
        let groups = grouped(entries: entries)
        return List {
            Section {
                StatsCardGrid(stats: stats)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 8)
            }
            ForEach(groups, id: \.label) { group in
                Section(group.label) {
                    ForEach(group.entries) { entry in
                        EntryRow(entry: entry)
                            .contentShape(.rect)
                            .onTapGesture { detail = entry }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(entry)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSeparator(.hidden)
    }

    private struct DateGroup { let label: String; let entries: [EntryRecord] }

    private func grouped(entries: [EntryRecord]) -> [DateGroup] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, MMM d"
        var order: [String] = []
        var map: [String: [EntryRecord]] = [:]
        for e in entries {
            let key = f.string(from: e.timestamp)
            if map[key] == nil { order.append(key) }
            map[key, default: []].append(e)
        }
        return order.map { DateGroup(label: $0, entries: map[$0] ?? []) }
    }

    private func delete(_ entry: EntryRecord) {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        try? store.delete(entry)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No history yet", systemImage: "clock")
        } description: {
            Text("Your bought and skipped items will show up here.")
        }
    }
}

struct StatsCardGrid: View {
    let stats: HistoryStats

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                statCard(label: "Total tracked", value: "\(stats.total)")
                statCard(label: "Total amount", value: Formatters.currency(stats.totalAmount))
                statCard(label: "Bought",
                         value: Formatters.minutes(stats.boughtMinutes),
                         sub: Formatters.currency(stats.boughtAmount),
                         tint: .green)
                statCard(label: "Skipped",
                         value: Formatters.minutes(stats.skippedMinutes),
                         sub: Formatters.currency(stats.skippedAmount),
                         tint: .red)
            }
            ratioCard
        }
        .padding(.horizontal)
    }

    private func statCard(label: String, value: String, sub: String? = nil, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).foregroundStyle(tint)
            if let sub { Text(sub).font(.caption2).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var ratioCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bought vs Skipped").font(.caption).foregroundStyle(.secondary)
            GeometryReader { geo in
                let buyW = geo.size.width * CGFloat(stats.boughtPercent) / 100
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.red.opacity(0.7))
                    Capsule().fill(Color.green.opacity(0.85))
                        .frame(width: max(0, buyW))
                }
            }
            .frame(height: 12)
            HStack {
                Text("\(stats.boughtPercent)% bought").font(.caption2).foregroundStyle(.green)
                Spacer()
                Text("\(stats.skippedPercent)% skipped").font(.caption2).foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EntryRow: View {
    let entry: EntryRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(DefaultCategories.emoji(of: entry.category))
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(.regularMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.body.weight(.medium)).lineLimit(1)
                Text(RelativeTime.format(entry.timestamp))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.currency(entry.amount))
                    .font(.body.monospacedDigit())
                Text(Formatters.minutes(entry.minutes))
                    .font(.caption).foregroundStyle(.secondary)
                badge
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var badge: some View {
        let (label, tint): (String, Color) = {
            switch entry.decision {
            case .buy: return ("Bought", .green)
            case .skip: return ("Skipped", .red)
            case .watchlist: return ("Watchlist", Theme.brand)
            }
        }()
        return Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}
