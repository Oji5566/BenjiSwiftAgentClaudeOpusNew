import SwiftUI
import SwiftData

/// Five-step native onboarding. Each step is a SwiftUI subview with a
/// shared progress indicator. Mirrors the flow of the original web
/// onboarding (welcome → income type → amount → hours/week → real wage →
/// confirm rate).
struct OnboardingView: View {
    @Environment(SessionStore.self) private var session
    @Bindable var user: UserAccount

    @State private var step: Int = 1
    @State private var draft = EarningSettings(incomeType: .hourly,
                                               incomeAmount: 0,
                                               hoursPerWeek: 40,
                                               realWageEnabled: false,
                                               monthlyFixedExpenses: 0)
    @State private var amountString: String = ""
    @State private var hoursString: String = "40"
    @State private var expensesString: String = ""
    @State private var validationMessage: String?

    private let totalSteps = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progress

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch step {
                        case 1: stepIncomeType
                        case 2: stepIncomeAmount
                        case 3: stepHours
                        case 4: stepRealWage
                        default: stepReview
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                actions
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Welcome, \(user.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { session.signOut() }
                        .tint(.red)
                }
            }
        }
    }

    // MARK: - Steps

    private var stepIncomeType: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("How do you earn?", subtitle: "We'll use this to convert money into time.")
            Picker("Income type", selection: $draft.incomeType) {
                ForEach(IncomeType.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var stepIncomeAmount: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(draft.incomeType.amountFieldLabel,
                         subtitle: "Just an honest take-home figure works best.")
            HStack {
                Text("$").foregroundStyle(.secondary)
                TextField("0", text: $amountString)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var stepHours: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Hours per week",
                         subtitle: "How many hours do you typically work?")
            TextField("40", text: $hoursString)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var stepRealWage: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Real wage mode",
                         subtitle: "Subtract your fixed monthly expenses to see how much money you actually keep per minute worked.")
            Toggle("Real wage mode", isOn: $draft.realWageEnabled)
                .tint(Theme.brand)
            if draft.realWageEnabled {
                Text("Monthly fixed expenses").font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    Text("$").foregroundStyle(.secondary)
                    TextField("0", text: $expensesString)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var stepReview: some View {
        let live = currentDraft()
        let rate = EarningRateCalculator.perMinute(live)
        return VStack(alignment: .leading, spacing: 16) {
            sectionTitle("You're all set",
                         subtitle: "Here's how much you earn per minute of work.")
            VStack(spacing: 6) {
                Text(Formatters.ratePerMinute(rate))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.brand)
                Text("You can change this anytime in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard()
        }
    }

    // MARK: - Chrome

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.brand : Color(.systemGray4))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 24)
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2).bold()
            Text(subtitle).foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack {
            Button(role: .cancel) { back() } label: {
                Text(step == 1 ? "Sign out" : "Back")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)

            Button { advance() } label: {
                Text(step == totalSteps ? "Get Started" : "Continue")
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Logic

    private func currentDraft() -> EarningSettings {
        var d = draft
        d.incomeAmount = Double(amountString) ?? 0
        d.hoursPerWeek = Double(hoursString) ?? 40
        d.monthlyFixedExpenses = Double(expensesString) ?? 0
        return d
    }

    private func validateCurrentStep() -> Bool {
        validationMessage = nil
        switch step {
        case 2:
            let amt = Double(amountString) ?? 0
            if amt <= 0 { validationMessage = "Please enter a valid income amount."; return false }
            draft.incomeAmount = amt
        case 3:
            let hrs = Double(hoursString) ?? 0
            if hrs <= 0 || hrs > 168 {
                validationMessage = "Please enter valid hours (1-168)."; return false
            }
            draft.hoursPerWeek = hrs
        case 4:
            if draft.realWageEnabled {
                draft.monthlyFixedExpenses = Double(expensesString) ?? 0
            } else {
                draft.monthlyFixedExpenses = 0
            }
        default: break
        }
        return true
    }

    private func advance() {
        guard validateCurrentStep() else { return }
        if step < totalSteps {
            withAnimation(.snappy) { step += 1 }
        } else {
            session.completeOnboarding(with: currentDraft())
        }
    }

    private func back() {
        if step == 1 {
            session.signOut()
        } else {
            withAnimation(.snappy) { step -= 1 }
        }
    }
}
