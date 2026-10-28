import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorCredentialsReaderTests {
    let paths = CursorPaths(home: URL(filePath: "/home"))
    let beforeExpiry = Date.iso("2026-10-10T20:00:00Z")

    func token(
        _ database: FakeKeyValueDatabase,
        secrets: FakeSecretReader = CursorSafeStorageTests.secrets,
        at now: Date
    ) throws(ProviderIssue) -> CursorAccessToken {
        let safeStorage = CursorSafeStorage(secrets: secrets, decryptor: CursorSafeStorageTests.decryptor)
        return try CursorCredentialsReader(database: database, safeStorage: safeStorage, paths: paths).validToken(at: now)
    }

    @Test func returnsAValidToken() throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        #expect(try token(database, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 a plain token never reads the Keychain")
    func plainTokenNeverReadsTheKeychain() throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        let deniesEveryRead = FakeSecretReader(deniesAccess: true)
        #expect(try token(database, secrets: deniesEveryRead, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 a token Cursor encrypted at rest reads as the JWT it holds")
    func encryptedTokenReadsAsItsJWT() throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorSafeStorageTests.stored])
        #expect(try token(database, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 no database or no row is not found")
    func missingRowOrDatabaseIsNotFound() {
        #expect(throws: ProviderIssue.notFound) { try token(FakeKeyValueDatabase(), at: beforeExpiry) }
        #expect(throws: ProviderIssue.notFound) { try token(FakeKeyValueDatabase(failure: .missing), at: beforeExpiry) }
    }

    @Test("B-26 a database still locked when the timeout runs out reads as offline, so the next refresh tries again")
    func busyDatabaseIsOffline() {
        #expect(throws: ProviderIssue.offline) { try token(FakeKeyValueDatabase(failure: .busy), at: beforeExpiry) }
    }

    @Test("B-26 a database that can't be read otherwise is unexpected")
    func unreadableDatabaseIsUnexpected() {
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor's state database can't be read")) {
            try token(FakeKeyValueDatabase(failure: .unreadable), at: beforeExpiry)
        }
    }

    @Test("B-26 an expired token is sign-in expired, encrypted or not", arguments: [
        CursorAccessTokenTests.jwt, CursorSafeStorageTests.stored,
    ])
    func expiredTokenIsSignInExpired(stored: String) {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: stored])
        #expect(throws: ProviderIssue.signInExpired) { try token(database, at: .iso("2026-11-27T00:00:00Z")) }
    }

    @Test func readsTheDesktopAppDatabase() {
        #expect(paths.stateDatabase.path == "/home/Library/Application Support/Cursor/User/globalStorage/state.vscdb")
    }
}
