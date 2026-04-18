import Foundation
import SwiftData

/// Owns the app's `ModelContainer`. A single shared container is created
/// at app launch and injected into the SwiftUI environment.
enum PersistenceController {

    /// Build a container backed by the on-disk store. Falls back to an
    /// in-memory store if the on-disk store can't be opened (e.g. corrupt
    /// schema during development).
    static func makeSharedContainer() -> ModelContainer {
        let schema = Schema([
            UserAccount.self,
            AppSettingsRecord.self,
            EntryRecord.self,
            CategoryRecord.self
        ])
        let onDisk = ModelConfiguration("Benji", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [onDisk])
        } catch {
            // Last-ditch: in-memory so the app still launches.
            let inMem = ModelConfiguration("Benji", schema: schema, isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [inMem])
        }
    }

    /// In-memory container for previews and tests.
    static func makePreviewContainer() -> ModelContainer {
        let schema = Schema([
            UserAccount.self, AppSettingsRecord.self, EntryRecord.self, CategoryRecord.self
        ])
        let cfg = ModelConfiguration("BenjiPreview", schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [cfg])
    }
}
