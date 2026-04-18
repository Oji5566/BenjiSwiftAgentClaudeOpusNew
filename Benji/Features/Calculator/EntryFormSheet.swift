import SwiftUI

/// Final entry-form sheet — ask for a name and category for the just-tracked
/// purchase before saving it. Native `Form` + segmented category picker.
struct EntryFormSheet: View {
    let amount: Double
    let minutes: Double
    let decision: Decision
    let onSave: (_ name: String, _ category: String) -> Void

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = ""
    @FocusState private var nameFocused: Bool

    private var categories: [String] {
        session.currentUser?.orderedCategories.map(\.name) ?? DefaultCategories.all
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Amount", value: Formatters.currency(amount))
                    LabeledContent("Time", value: Formatters.minutes(minutes))
                    LabeledContent("Decision", value: decision.displayName)
                }

                Section("Name") {
                    TextField("e.g. Latte", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Save \(decision.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespaces), category.isEmpty ? "❓ Other" : category)
                    }.bold()
                }
            }
            .onAppear {
                if category.isEmpty { category = categories.first ?? "❓ Other" }
                nameFocused = true
            }
        }
    }
}
