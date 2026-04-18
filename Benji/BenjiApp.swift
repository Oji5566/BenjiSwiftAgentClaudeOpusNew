import SwiftUI
import SwiftData

@main
struct BenjiApp: App {
    private let container = PersistenceController.makeSharedContainer()
    @State private var session: SessionStore

    init() {
        let context = container.mainContext
        _session = State(initialValue: SessionStore(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .modelContainer(container)
        }
    }
}
