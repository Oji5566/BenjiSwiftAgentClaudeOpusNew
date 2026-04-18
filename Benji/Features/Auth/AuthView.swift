import SwiftUI

/// Combined Login / Sign-up screen. Mirrors the original web flow
/// (segmented switch between modes), but built with native form controls,
/// `TextField`/`SecureField`, and Dynamic-Type-friendly typography.
struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        var id: String { rawValue }
    }

    @Environment(SessionStore.self) private var session

    @State private var mode: Mode = .signIn
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    @FocusState private var focused: Field?
    private enum Field { case username, password, confirm }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: mode) { _, _ in errorMessage = nil }

                    formCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    Button(action: submit) {
                        HStack {
                            if isWorking { ProgressView().tint(.white) }
                            Text(mode == .signIn ? "Sign In" : "Create Account").bold()
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isWorking)
                    .padding(.horizontal)

                    Text("Your data stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 32)
                }
                .padding(.top, 32)
            }
            .background(Color(.systemBackground))
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(Theme.brand)
                .accessibilityHidden(true)
            Text("Benji")
                .font(.largeTitle).bold()
            Text("See purchases through work time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private var formCard: some View {
        VStack(spacing: 12) {
            TextField("Username", text: $username)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused, equals: .username)
                .submitLabel(.next)
                .onSubmit { focused = .password }

            SecureField("Password", text: $password)
                .textContentType(mode == .signIn ? .password : .newPassword)
                .focused($focused, equals: .password)
                .submitLabel(mode == .signIn ? .go : .next)
                .onSubmit {
                    if mode == .signIn { submit() } else { focused = .confirm }
                }

            if mode == .signUp {
                SecureField("Confirm password", text: $confirm)
                    .textContentType(.newPassword)
                    .focused($focused, equals: .confirm)
                    .submitLabel(.go)
                    .onSubmit { submit() }
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal)
    }

    private func submit() {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            switch mode {
            case .signIn:
                try session.signIn(username: username, password: password)
            case .signUp:
                try session.signUp(username: username, password: password, confirm: confirm)
            }
            password = ""
            confirm = ""
        } catch let err as AccountStore.AuthError {
            errorMessage = err.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
