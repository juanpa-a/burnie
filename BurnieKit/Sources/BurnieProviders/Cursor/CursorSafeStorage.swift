import BurnieDomain
import BurnieInterface
import Foundation

/// Decrypts the session Cursor encrypted at rest, with the password in Cursor's Keychain item (B-26). Never writes.
struct CursorSafeStorage: Sendable {
    static let keychainService = "Cursor Safe Storage"
    static let keychainAccount = "Cursor"

    let secrets: any SecretReader
    let decryptor: any SafeStorageDecryptor

    /// No Keychain item, or no access to it → missing Keychain access; a value the password doesn't open, or that
    /// doesn't open to text → unexpected.
    func jwt(decrypting value: Data) throws(ProviderIssue) -> String {
        let password = try keychainPassword()
        guard let plaintext = decryptor.decrypt(value, password: password),
              let jwt = String(data: plaintext, encoding: .utf8)
        else {
            throw .unexpectedResponse("Cursor's encrypted session can't be decrypted")
        }
        return jwt
    }

    /// Cursor made the item, so macOS asks the user before the first read; a denial throws.
    private func keychainPassword() throws(ProviderIssue) -> Data {
        guard let password = try? secrets.genericPassword(service: Self.keychainService, account: Self.keychainAccount) else {
            throw .specific(.missingKeychainAccess)
        }
        return password
    }
}
