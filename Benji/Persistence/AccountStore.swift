import Foundation
import SwiftData

/// Authentication & account-bootstrap operations against SwiftData +
/// Keychain. Pure logic — no UI types.
struct AccountStore {
    enum AuthError: LocalizedError, Equatable {
        case missingFields
        case usernameTooShort
        case passwordTooShort
        case passwordMismatch
        case usernameTaken
        case unknownAccount
        case wrongPassword

        var errorDescription: String? {
            switch self {
            case .missingFields:    return "Please fill in all fields."
            case .usernameTooShort: return "Username must be at least 3 characters."
            case .passwordTooShort: return "Password must be at least 6 characters."
            case .passwordMismatch: return "Passwords do not match."
            case .usernameTaken:    return "Username already taken. Choose another."
            case .unknownAccount:   return "Account not found. Please sign up."
            case .wrongPassword:    return "Incorrect password. Try again."
            }
        }
    }

    let context: ModelContext

    // MARK: - Lookup

    func account(for username: String) -> UserAccount? {
        var d = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.username == username })
        d.fetchLimit = 1
        return (try? context.fetch(d))?.first
    }

    // MARK: - Sign up

    @discardableResult
    func signUp(username rawUsername: String, password: String, confirm: String) throws -> UserAccount {
        let username = rawUsername.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty, !password.isEmpty else { throw AuthError.missingFields }
        guard username.count >= 3 else { throw AuthError.usernameTooShort }
        guard password.count >= 6 else { throw AuthError.passwordTooShort }
        guard password == confirm else { throw AuthError.passwordMismatch }
        guard account(for: username) == nil else { throw AuthError.usernameTaken }

        let user = UserAccount(username: username)
        let settings = AppSettingsRecord()
        user.settings = settings
        // Seed default categories
        for (i, name) in DefaultCategories.all.enumerated() {
            let c = CategoryRecord(name: name, sortIndex: i, owner: user)
            user.categories.append(c)
            context.insert(c)
        }
        context.insert(settings)
        context.insert(user)
        try context.save()

        KeychainService.setPasswordHash(PasswordHasher.sha256Hex(password), for: username)
        KeychainService.setActiveUsername(username)
        return user
    }

    // MARK: - Sign in

    @discardableResult
    func signIn(username rawUsername: String, password: String) throws -> UserAccount {
        let username = rawUsername.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty, !password.isEmpty else { throw AuthError.missingFields }
        guard let user = account(for: username) else { throw AuthError.unknownAccount }
        let expected = KeychainService.passwordHash(for: username)
        let actual = PasswordHasher.sha256Hex(password)
        guard expected == actual else { throw AuthError.wrongPassword }
        KeychainService.setActiveUsername(username)
        return user
    }

    /// Restore the previously signed-in account, if any.
    func restoreSession() -> UserAccount? {
        guard let name = KeychainService.activeUsername() else { return nil }
        return account(for: name)
    }

    func signOut() {
        KeychainService.setActiveUsername(nil)
    }
}
