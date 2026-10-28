import BurnieInterface
import Foundation
import Security

/// Reads Keychain items with the Security framework, from Burnie's own process. For an item another app made, macOS
/// asks the user once, and Always Allow grants Burnie alone, never `/usr/bin/security`, which any process can run.
public struct SecurityFrameworkKeychain: SecretReader {
    public enum Failure: Error {
        case status(OSStatus)
    }

    public init() {}

    /// Throws when the user denies access, or the Keychain fails otherwise. The password is never logged (X-3).
    public func genericPassword(service: String, account: String?) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        if let account {
            query[kSecAttrAccount as String] = account
        }
        var password: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &password) {
        case errSecSuccess: return password as? Data
        case errSecItemNotFound: return nil
        case let status: throw Failure.status(status)
        }
    }
}
