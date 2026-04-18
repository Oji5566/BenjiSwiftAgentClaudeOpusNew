import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @State private var exportURL: URL?
    @State private var showClearConfirm = false
    @State private var showLogoutConfirm = false
    @State private var addingCategory = false
    @State private var newCategoryName = ""
    @State private var renamingCategory: CategoryRecord?
    @State private var renameDraft = ""

    private let appVersion: String = {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return v
    }()

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                if let user = session.currentUser, let settings = user.settings {
                    incomeSection(settings: settings)
                    realWageSection(settings: settings)
                    categoriesSection(user: user)
                }
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog("Clear all history?",
                                isPresented: $showClearConfirm,
                                titleVisibility: .visible) {
                Button("Clear All", role: .destructive) { clearHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your spending entries. This action cannot be undone.")
            }
            .confirmationDialog("Sign out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { session.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("New Category", isPresented: $addingCategory) {
                TextField("Category", text: $newCategoryName)
                Button("Add") { commitAddCategory() }
                Button("Cancel", role: .cancel) { newCategoryName = "" }
            } message: {
                Text("Tip: prefix with an emoji to give it a quick icon.")
            }
            .alert("Rename Category", isPresented: Binding(get: { renamingCategory != nil },
                                                          set: { if !$0 { renamingCategory = nil } })) {
                TextField("Category", text: $renameDraft)
                Button("Save") { commitRename() }
                Button("Cancel", role: .cancel) { renamingCategory = nil }
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profile") {
            LabeledContent("Username", value: session.currentUser?.username ?? "—")
            Button(role: .destructive) { showLogoutConfirm = true } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private func incomeSection(settings: AppSettingsRecord) -> some View {
        Section("Income") {
            Picker("Type", selection: Binding(
                get: { settings.incomeType },
                set: { newType in session.updateSettings { $0.incomeType = newType } }
            )) {
                ForEach(IncomeType.allCases) { Text($0.displayName).tag($0) }
            }

            HStack {
                Text("Amount")
                Spacer()
                Text("$").foregroundStyle(.secondary)
                TextField("Amount", value: Binding(
                    get: { settings.incomeAmount },
                    set: { v in session.updateSettings { $0.incomeAmount = max(0, v) } }
                ), format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }

            HStack {
                Text("Hours / Week")
                Spacer()
                TextField("Hours", value: Binding(
                    get: { settings.hoursPerWeek },
                    set: { v in session.updateSettings { $0.hoursPerWeek = max(1, min(168, v)) } }
                ), format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 120)
            }

            LabeledContent("Current rate",
                           value: Formatters.ratePerMinute(EarningRateCalculator.perMinute(settings.asEarningSettings)))
                .foregroundStyle(.secondary)
        }
    }

    private func realWageSection(settings: AppSettingsRecord) -> some View {
        Section {
            Toggle("Real Wage Mode", isOn: Binding(
                get: { settings.realWageEnabled },
                set: { v in session.updateSettings { $0.realWageEnabled = v } }
            ))
            if settings.realWageEnabled {
                HStack {
                    Text("Monthly Expenses")
                    Spacer()
                    Text("$").foregroundStyle(.secondary)
                    TextField("0", value: Binding(
                        get: { settings.monthlyFixedExpenses },
                        set: { v in session.updateSettings { $0.monthlyFixedExpenses = max(0, v) } }
                    ), format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
                LabeledContent("Adjusted rate",
                               value: Formatters.ratePerMinute(EarningRateCalculator.perMinute(settings.asEarningSettings)))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Real Wages")
        } footer: {
            Text("Subtracts your fixed monthly expenses from your effective earnings.")
        }
    }

    private func categoriesSection(user: UserAccount) -> some View {
        Section {
            ForEach(user.orderedCategories) { cat in
                Text(cat.name)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(cat, in: user) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            renamingCategory = cat
                            renameDraft = cat.name
                        } label: { Label("Rename", systemImage: "pencil") }
                            .tint(Theme.brand)
                    }
            }
            .onMove { source, destination in
                let store = CategoryStore(context: modelContext, user: user)
                try? store.move(from: source, to: destination)
            }
            Button { addingCategory = true } label: {
                Label("Add Category", systemImage: "plus.circle.fill")
            }
        } header: {
            HStack {
                Text("Categories")
                Spacer()
                EditButton().font(.caption)
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            if let url = exportURL {
                ShareLink(item: url) {
                    Label("Share Export", systemImage: "square.and.arrow.up")
                }
            } else {
                Button { prepareExport() } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("Clear History", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
        }
    }

    // MARK: - Actions

    private func prepareExport() {
        guard let user = session.currentUser else { return }
        let payload = ExportService.payload(for: user)
        do {
            exportURL = try ExportService.writeTemporaryFile(for: payload)
        } catch {
            exportURL = nil
        }
    }

    private func commitAddCategory() {
        defer { newCategoryName = "" }
        guard let user = session.currentUser else { return }
        let store = CategoryStore(context: modelContext, user: user)
        try? store.add(newCategoryName)
    }

    private func commitRename() {
        guard let cat = renamingCategory, let user = session.currentUser else { return }
        let store = CategoryStore(context: modelContext, user: user)
        try? store.rename(cat, to: renameDraft)
        renamingCategory = nil
    }

    private func delete(_ cat: CategoryRecord, in user: UserAccount) {
        let store = CategoryStore(context: modelContext, user: user)
        try? store.delete(cat)
    }

    private func clearHistory() {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        try? store.clearAll()
        exportURL = nil
    }
}
