import Foundation

/// Keychain reads. Never writes.
public protocol SecretReader: Sendable {
    /// nil if the item doesn't exist.
    func genericPassword(service: String, account: String?) throws -> Data?
}
