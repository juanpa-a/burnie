import BurnieDomain
import BurnieInterface
import Foundation

/// Reads the Cursor app's token from `state.vscdb` right before each request. Never writes.
struct CursorCredentialsReader: Sendable {
    static let table = "ItemTable"
    static let tokenKey = "cursorAuth/accessToken"

    let database: any KeyValueDatabase
    let paths: CursorPaths

    /// No database or no row → not found; an expired or malformed token → sign-in expired, without touching the
    /// network (B-26).
    func validToken(at now: Date) throws(ProviderIssue) -> CursorAccessToken {
        guard let jwt = try storedToken() else { throw .notFound }
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
}
