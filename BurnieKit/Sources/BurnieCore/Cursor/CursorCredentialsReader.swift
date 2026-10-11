import Foundation

/// Reads the Cursor app's token from `state.vscdb` right before each request. Never writes.
public struct CursorCredentialsReader: Sendable {
    static let table = "ItemTable"
    static let tokenKey = "cursorAuth/accessToken"

    private let database: KeyValueDatabase
    private let stateDatabase: URL

    public init(database: KeyValueDatabase, paths: CursorPaths) {
        self.database = database
        stateDatabase = paths.stateDatabase
    }

    /// No database or no row → `.notFound`; expired or malformed token → `.signInExpired`, without touching the network.
    func validToken(at now: Date) throws(ProviderIssue) -> CursorAccessToken {
        guard let jwt = (try? database.value(forKey: Self.tokenKey, table: Self.table, at: stateDatabase)) ?? nil else {
            throw .notFound
        }
        let token = try CursorAccessToken(jwt: jwt)
        guard token.expiresAt > now else { throw .signInExpired }
        return token
    }
}
