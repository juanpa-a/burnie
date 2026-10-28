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
        keychain: FakeSecretReader = CursorSafeStorageTests.keychain(),
        at now: Date
    ) async throws(ProviderIssue) -> CursorAccessToken {
        let safeStorage = CursorSafeStorage(secrets: keychain, decryptor: CursorSafeStorageTests.decryptor)
        return try await CursorCredentialsReader(database: database, safeStorage: safeStorage, paths: paths).validToken(at: now)
    }

    @Test func returnsAValidToken() async throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        #expect(try await token(database, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 a plain token never reads the Keychain")
    func plainTokenNeverReadsTheKeychain() async throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
        let keychain = CursorSafeStorageTests.keychain()
        #expect(try await token(database, keychain: keychain, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
        #expect(keychain.reads == 0)
    }

    @Test("B-26 a token Cursor encrypted at rest reads as the JWT it holds")
    func encryptedTokenReadsAsItsJWT() async throws {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorSafeStorageTests.stored])
        #expect(try await token(database, at: beforeExpiry).jwt == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 no database or no row is not found")
    func missingRowOrDatabaseIsNotFound() async {
        await #expect(throws: ProviderIssue.notFound) { try await token(FakeKeyValueDatabase(), at: beforeExpiry) }
        await #expect(throws: ProviderIssue.notFound) { try await token(FakeKeyValueDatabase(failure: .missing), at: beforeExpiry) }
    }

    @Test("B-26 a database still locked when the timeout runs out reads as offline, so the next refresh tries again")
    func busyDatabaseIsOffline() async {
        await #expect(throws: ProviderIssue.offline) { try await token(FakeKeyValueDatabase(failure: .busy), at: beforeExpiry) }
    }

    @Test("B-26 a database that can't be read otherwise is unexpected")
    func unreadableDatabaseIsUnexpected() async {
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor's state database can't be read")) {
            try await token(FakeKeyValueDatabase(failure: .unreadable), at: beforeExpiry)
        }
    }

    @Test("B-26 an expired token is sign-in expired, encrypted or not", arguments: [
        CursorAccessTokenTests.jwt, CursorSafeStorageTests.stored,
    ])
    func expiredTokenIsSignInExpired(stored: String) async {
        let database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: stored])
        await #expect(throws: ProviderIssue.signInExpired) { try await token(database, at: .iso("2026-11-27T00:00:00Z")) }
    }

    @Test func readsTheDesktopAppDatabase() {
        #expect(paths.stateDatabase.path == "/home/Library/Application Support/Cursor/User/globalStorage/state.vscdb")
    }
}
