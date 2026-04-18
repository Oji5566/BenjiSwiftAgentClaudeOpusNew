import SwiftUI
import SwiftData

/// Calculator tab — premium native input screen with a hero amount/time
/// readout, a numeric keypad, and a sheet-based result flow.
struct CalculatorView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var modelContext

    @State private var input: String = "0"
    @State private var pending: PendingDecision?
    @State private var showSavedToast: Bool = false

    /// Amount + decision captured when the user taps a result-sheet action,
    /// before they complete the entry-form sheet.
    private struct PendingDecision: Identifiable {
        let id = UUID()
        let amount: Double
        let minutes: Double
        let decision: Decision
    }

    /// Last-tapped amount (for the action sheet step).
    @State private var resultDraft: ResultDraft?
    private struct ResultDraft: Identifiable {
        let id = UUID()
        let amount: Double
        let minutes: Double
        let rate: Double
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    rateChip
                    hero
                    KeypadView(onKey: handleKey, onEnter: handleEnter)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Benji")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) { if showSavedToast { savedToast } }
            .sheet(item: $resultDraft) { draft in
                ResultActionSheet(amount: draft.amount, minutes: draft.minutes, rate: draft.rate) { decision in
                    if let decision {
                        pending = PendingDecision(amount: draft.amount, minutes: draft.minutes, decision: decision)
                    }
                    resultDraft = nil
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $pending) { p in
                EntryFormSheet(amount: p.amount, minutes: p.minutes, decision: p.decision) { name, category in
                    save(name: name, category: category, decision: p.decision, amount: p.amount)
                    pending = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Hero & rate chip

    private var rateChip: some View {
        let rate = session.currentUser?.earningPerMinute ?? 0
        return HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Theme.brand)
            Text(Formatters.ratePerMinute(rate))
                .font(.caption.monospacedDigit())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("Current earning rate \(Formatters.ratePerMinute(rate))")
    }

    private var hero: some View {
        let rate = session.currentUser?.earningPerMinute ?? 0
        let amount = CalculatorInput.amount(from: input)
        let minutes = EarningRateCalculator.minutes(forAmount: amount, rate: rate)
        return VStack(spacing: 14) {
            Text(displayAmount)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if amount > 0 {
                Divider().opacity(0.4)
                if rate > 0 {
                    VStack(spacing: 4) {
                        Text("equals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.minutes(minutes))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.brand)
                    }
                } else {
                    Text("Set your income in Settings to calculate time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .glassCard()
        .padding(.horizontal)
    }

    private var displayAmount: String {
        let parts = input.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = Int(parts[0]) ?? 0
        let f = NumberFormatter()
        f.numberStyle = .decimal
        let intStr = f.string(from: NSNumber(value: intPart)) ?? "0"
        if parts.count > 1 { return "$\(intStr).\(parts[1])" }
        return "$\(intStr)"
    }

    private var savedToast: some View {
        Label("Saved", systemImage: "checkmark.circle.fill")
            .font(.callout.bold())
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .foregroundStyle(.green)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Actions

    private func handleKey(_ key: String) {
        input = CalculatorInput.apply(key: key, to: input)
    }

    private func handleEnter() {
        let amount = CalculatorInput.amount(from: input)
        guard amount > 0 else { return }
        let rate = session.currentUser?.earningPerMinute ?? 0
        let minutes = EarningRateCalculator.minutes(forAmount: amount, rate: rate)
        resultDraft = ResultDraft(amount: amount, minutes: minutes, rate: rate)
    }

    private func save(name: String, category: String, decision: Decision, amount: Double) {
        guard let user = session.currentUser else { return }
        let store = EntryStore(context: modelContext, user: user)
        do {
            try store.add(name: name, amount: amount, decision: decision, category: category)
            input = "0"
            withAnimation(.snappy) { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { showSavedToast = false }
            }
        } catch {
            // Persistence errors swallowed — UI shows nothing changed.
        }
    }
}
