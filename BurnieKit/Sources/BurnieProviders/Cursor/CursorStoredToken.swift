import BurnieDomain
import Foundation

/// What the Cursor app keeps under `cursorAuth/accessToken`: its session JWT, or, with Cursor's encryption at rest on,
/// that JWT encrypted with its safe storage, written as `cursor-safe-storage:v1:` and the base64 of the encrypted value.
enum CursorStoredToken: Equatable {
    case plain(jwt: String)
    /// The safe storage value: `v10` and its ciphertext.
    case encrypted(Data)

    static let envelopePrefix = "cursor-safe-storage:v1:"

    /// An envelope whose rest isn't base64 is unexpected: Cursor changed something Burnie can't read (B-26).
    init(_ stored: String) throws(ProviderIssue) {
        guard stored.hasPrefix(Self.envelopePrefix) else {
            self = .plain(jwt: stored)
            return
        }
        guard let value = Data(base64Encoded: String(stored.dropFirst(Self.envelopePrefix.count))) else {
            throw .unexpectedResponse("Cursor's encrypted session isn't base64")
        }
        self = .encrypted(value)
    }
}
