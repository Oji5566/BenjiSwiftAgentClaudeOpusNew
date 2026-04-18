import Foundation
import SwiftData
import Observation

/// Global session state. Holds the currently signed-in account (if any)
/// and exposes auth operations to SwiftUI.
@Observable
@MainActor
final class SessionStore {
    var currentUser: UserAccount?
    private(set) var didRestore: Bool = false

    private let context: ModelContext
    private(set) lazy var accountStore = AccountStore(context: context)

    init(context: ModelContext) {
        self.context = context
    }

    func bootstrap() {
        guard !didRestore else { return }
        currentUser = accountStore.restoreSession()
        didRestore = true
    }

    func signIn(username: String, password: String) throws {
        currentUser = try accountStore.signIn(username: username, password: password)
    }

    func signUp(username: String, password: String, confirm: String) throws {
        currentUser = try accountStore.signUp(username: username, password: password, confirm: confirm)
    }

    func signOut() {
        accountStore.signOut()
        currentUser = nil
    }

    /// Persist updated settings on the current user and bump SwiftData.
    func updateSettings(_ mutate: (AppSettingsRecord) -> Void) {
        guard let user = currentUser else { return }
        let settings = user.settings ?? AppSettingsRecord()
        if user.settings == nil {
            context.insert(settings)
            user.settings = settings
        }
        mutate(settings)
        try? context.save()
    }

    func completeOnboarding(with settings: EarningSettings) {
        updateSettings { rec in
            rec.apply(settings)
            rec.onboardingComplete = true
        }
    }
}
