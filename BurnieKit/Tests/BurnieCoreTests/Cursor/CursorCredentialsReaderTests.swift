import Foundation
import Testing
@testable import BurnieCore

struct CursorCredentialsReaderTests {
    let paths = CursorPaths(home: URL(filePath: "/home"))
    let beforeExpiry = Date.iso("2026-10-10T20:00:00Z")

    func token(_ database: FakeKeyValueDatabase, at now: Date) throws(ProviderIssue) -> CursorAccessToken {
        try CursorCredentialsReader(database: database, paths: paths).validToken(at: now)
    }

    @Test func returnsAValidToken() throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        #expect(try token(database, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test func missingRowOrDatabaseIsNotFound() {
        #expect(throws: ProviderIssue.notFound) { try token(FakeKeyValueDatabase(), at: beforeExpiry) }
        #expect(throws: ProviderIssue.notFound) { try token(FakeKeyValueDatabase(failure: CocoaError(.fileNoSuchFile)), at: beforeExpiry) }
    }

    @Test func expiredTokenIsSignInExpired() {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        #expect(throws: ProviderIssue.signInExpired) { try token(database, at: .iso("2026-11-27T00:00:00Z")) }
    }

    @Test func readsTheDesktopAppDatabase() {
        #expect(paths.stateDatabase.path == "/home/Library/Application Support/Cursor/User/globalStorage/state.vscdb")
    }
}
