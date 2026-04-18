import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

/// Hashing helpers used by the local account system.
///
/// The web app stored a hex SHA-256 digest of the user's password in
/// `localStorage`. We preserve the same hash format so behaviour is
/// well-defined and easy to test, but in the native app we keep the
/// digest in the iOS Keychain rather than in user-defaults.
public enum PasswordHasher {

    /// Hex-encoded SHA-256 digest of `password`.
    public static func sha256Hex(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
