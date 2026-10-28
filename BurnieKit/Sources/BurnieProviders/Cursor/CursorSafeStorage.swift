import BurnieDomain
import BurnieInterface
import Foundation

/// Decrypts the session Cursor encrypted at rest, with the password in Cursor's Keychain item (B-26). Never writes.
///
/// It keeps that password in memory once read, never on disk (a memo, P-5): the Keychain is read once per launch
/// instead of on every refresh, and both tasks share that read, so macOS asks once. A missing item or a denied read
/// keeps nothing, so the next refresh asks again.
actor CursorSafeStorage {
    static let keychainService = "Cursor Safe Storage"
    /// Electron names the account after the app, followed by " Key".
    static let keychainAccount = "Cursor Key"

    private let secrets: any SecretReader
    private let decryptor: any SafeStorageDecryptor
    private var password: Data?

    init(secrets: any SecretReader, decryptor: any SafeStorageDecryptor) {
        self.secrets = secrets
        self.decryptor = decryptor
    }

    /// No Keychain item, or no access to it → missing Keychain access; a value the password doesn't open, or that
    /// doesn't open to text → unexpected.
    func jwt(decrypting value: Data) throws(ProviderIssue) -> String {
        if let password, let jwt = open(value, with: password) { return jwt }
        // Nothing kept yet, or Cursor's password changed since: a fresh read decides, as it would without the memo.
        let fresh = try keychainPassword()
        password = fresh
        guard let jwt = open(value, with: fresh) else {
            throw .unexpectedResponse("Cursor's encrypted session can't be decrypted")
        }
        return jwt
    }

    private func open(_ value: Data, with password: Data) -> String? {
        decryptor.decrypt(value, password: password).flatMap { String(data: $0, encoding: .utf8) }
    }

    /// Cursor made the item, so macOS asks the user before the first read; a denial throws.
    private func keychainPassword() throws(ProviderIssue) -> Data {
        guard let password = try? secrets.genericPassword(service: Self.keychainService, account: Self.keychainAccount) else {
            throw .specific(.missingKeychainAccess)
        }
        return password
    }
}
