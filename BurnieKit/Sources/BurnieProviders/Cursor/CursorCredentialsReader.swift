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
        guard let jwt = (try? database.value(forKey: Self.tokenKey, table: Self.table, at: paths.stateDatabase)) ?? nil else {
            throw .notFound
        }
        let token = try CursorAccessToken(jwt: jwt)
        guard token.expiresAt > now else { throw .signInExpired }
        return token
    }
}
