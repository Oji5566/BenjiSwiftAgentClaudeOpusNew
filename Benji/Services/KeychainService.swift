import Foundation
import Security

/// Lightweight wrapper around the iOS Keychain. Stores per-username
/// password digests (and the persisted session pointer) so credentials
/// never live in `UserDefaults` or SwiftData.
enum KeychainService {

    private static let service = "app.benji.auth"
    private static let sessionAccount = "__session_username"

    // MARK: - Password digests

    static func setPasswordHash(_ hex: String, for username: String) {
        write(account: username, value: hex)
    }

    static func passwordHash(for username: String) -> String? {
        read(account: username)
    }

    static func deletePasswordHash(for username: String) {
        delete(account: username)
    }

    // MARK: - Session

    /// Persist the currently signed-in username. Cleared on log-out.
    static func setActiveUsername(_ username: String?) {
        if let username {
            write(account: sessionAccount, value: username)
        } else {
            delete(account: sessionAccount)
        }
    }

    static func activeUsername() -> String? {
        read(account: sessionAccount)
    }

    // MARK: - Generic implementation

    private static func write(account: String, value: String) {
        let data = Data(value.utf8)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(baseQuery as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            for (k, v) in attrs { addQuery[k] = v }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
