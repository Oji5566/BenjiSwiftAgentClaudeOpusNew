import Foundation
import SwiftData

/// A locally-stored user account. The password digest itself never lives
/// in SwiftData — it is kept in the iOS Keychain (see `KeychainService`).
@Model
final class UserAccount {
    @Attribute(.unique) var username: String
    var createdAt: Date

    // One-to-one settings record (see `AppSettingsRecord`).
    @Relationship(deleteRule: .cascade) var settings: AppSettingsRecord?

    // All tracked entries (history + watchlist).
    @Relationship(deleteRule: .cascade, inverse: \EntryRecord.owner)
    var entries: [EntryRecord] = []

    // User's category list (ordered by `sortIndex`).
    @Relationship(deleteRule: .cascade, inverse: \CategoryRecord.owner)
    var categories: [CategoryRecord] = []

    init(username: String, createdAt: Date = Date()) {
        self.username = username
        self.createdAt = createdAt
    }
}
