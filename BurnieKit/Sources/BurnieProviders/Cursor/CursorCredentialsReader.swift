import BurnieDomain
import BurnieInterface
import Foundation

/// Reads the Cursor app's token from `state.vscdb` right before each request. Never writes.
struct CursorCredentialsReader: Sendable {
    static let table = "ItemTable"
    static let tokenKey = "cursorAuth/accessToken"

    let database: any KeyValueDatabase
    let safeStorage: CursorSafeStorage
    let paths: CursorPaths

    /// No database or no row → not found; an expired or malformed token → sign-in expired, without touching the
    /// network. A token Cursor encrypted at rest is decrypted first; only such a token reads the Keychain (B-26).
    func validToken(at now: Date) async throws(ProviderIssue) -> CursorAccessToken {
        guard let stored = try storedToken() else { throw .notFound }
        let jwt = try await plainJWT(from: CursorStoredToken(stored))
        let token = try CursorAccessToken(jwt: jwt)
        guard token.expiresAt > now else { throw .signInExpired }
        return token
    }

    private func storedToken() throws(ProviderIssue) -> String? {
        do throws(KeyValueDatabaseFailure) {
            return try database.value(forKey: Self.tokenKey, table: Self.table, at: paths.stateDatabase)
        } catch {
            switch error {
            case .missing: throw .notFound
            // Cursor is writing to it: like a server that's down for a moment, the next refresh tries again (B-26).
            case .busy: throw .offline
            case .unreadable: throw .unexpectedResponse("Cursor's state database can't be read")
            }
        }
    }

    /// The JWT itself, decrypted when Cursor encrypted it.
    private func plainJWT(from stored: CursorStoredToken) async throws(ProviderIssue) -> String {
        switch stored {
        case .plain(let jwt): jwt
        case .encrypted(let value): try await safeStorage.jwt(decrypting: value)
        }
    }
}
