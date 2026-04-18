import SwiftUI
import SwiftData

/// Top-level router. Decides between the auth flow, onboarding, and the
/// main tab bar based on the session state.
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if let user = session.currentUser {
                if user.onboardingComplete {
                    MainTabView()
                } else {
                    OnboardingView(user: user)
                }
            } else {
                AuthView()
            }
        }
        .animation(.snappy(duration: 0.25), value: session.currentUser?.persistentModelID)
        .animation(.snappy(duration: 0.25), value: session.currentUser?.onboardingComplete)
        .task { session.bootstrap() }
    }
}
