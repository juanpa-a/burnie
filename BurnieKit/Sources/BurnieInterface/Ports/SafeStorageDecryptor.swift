import Foundation

/// Opens a value an Electron app encrypted at rest with its safe storage (Chromium's OSCrypt on macOS), with the
/// password the app keeps in the Keychain. Computation only: the password comes through `SecretReader`.
public protocol SafeStorageDecryptor: Sendable {
    /// The plaintext, or nil when `value` isn't a safe storage value or `password` doesn't open it.
    func decrypt(_ value: Data, password: Data) -> Data?
}
