import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorSafeStorageTests {
    /// Cursor's Keychain password, invented.
    static let password = Data("invented-safe-storage-password".utf8)
    /// What `state.vscdb` holds with Cursor's encryption at rest on: the JWT of `cursor-jwt.txt`, encrypted with
    /// `password` as Chromium's OSCrypt does on macOS.
    static let stored = Fixture.text("cursor-encrypted-jwt.txt").trimmingCharacters(in: .whitespacesAndNewlines)
    static let encrypted = Data(base64Encoded: String(stored.dropFirst(CursorStoredToken.envelopePrefix.count)))!
    /// Opens the fixture with `password`; the real decryption is `CommonCryptoSafeStorageDecryptor`'s, tested in Infra.
    static let decryptor = FakeSafeStorageDecryptor(seals: [
        encrypted: .init(password: password, plaintext: Data(CursorAccessTokenTests.jwt.utf8)),
    ])

    /// Cursor's Keychain item, in a Keychain of its own for each test.
    static func keychain() -> FakeSecretReader {
        FakeSecretReader(items: [CursorSafeStorage.keychainService: password])
    }

    let keychain = Self.keychain()
    var decryptor = Self.decryptor

    /// A new one on every access, with nothing kept: a test that checks the memo holds on to one.
    var safeStorage: CursorSafeStorage {
        CursorSafeStorage(secrets: keychain, decryptor: decryptor)
    }

    @Test("B-26 an encrypted session opens with Cursor's Keychain item")
    func opensWithCursorsKeychainItem() async throws {
        #expect(CursorSafeStorage.keychainService == "Cursor Safe Storage")
        #expect(CursorSafeStorage.keychainAccount == "Cursor Key")
        #expect(try await safeStorage.jwt(decrypting: Self.encrypted) == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 without Cursor's Keychain item, Burnie needs Keychain access")
    func missingKeychainItemNeedsKeychainAccess() async {
        keychain.items = [:]
        await #expect(throws: ProviderIssue.specific(.missingKeychainAccess)) {
            try await safeStorage.jwt(decrypting: Self.encrypted)
        }
    }

    @Test("B-26 a denied Keychain read needs Keychain access")
    func deniedKeychainReadNeedsKeychainAccess() async {
        keychain.deniesAccess = true
        await #expect(throws: ProviderIssue.specific(.missingKeychainAccess)) {
            try await safeStorage.jwt(decrypting: Self.encrypted)
        }
    }

    @Test("B-26 a session the Keychain password doesn't open is unexpected")
    func wrongPasswordIsUnexpected() async {
        keychain.items = [CursorSafeStorage.keychainService: Data("another-password".utf8)]
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor's encrypted session can't be decrypted")) {
            try await safeStorage.jwt(decrypting: Self.encrypted)
        }
    }

    @Test("B-26 a session that doesn't open to text is unexpected")
    mutating func binaryPlaintextIsUnexpected() async {
        decryptor.seals[Self.encrypted] = .init(password: Self.password, plaintext: Data([0xFF, 0xFE, 0x00]))
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor's encrypted session can't be decrypted")) {
            try await safeStorage.jwt(decrypting: Self.encrypted)
        }
    }

    // MARK: Memo (P-5)

    @Test("B-26 the Keychain is read once: later sessions open with the password kept in memory")
    func readsTheKeychainOnce() async throws {
        let safeStorage = self.safeStorage
        _ = try await safeStorage.jwt(decrypting: Self.encrypted)
        _ = try await safeStorage.jwt(decrypting: Self.encrypted)
        #expect(keychain.reads == 1)
    }

    @Test("B-26 both of Cursor's tasks share one Keychain read, so macOS asks once")
    func concurrentSessionsShareOneRead() async throws {
        let safeStorage = self.safeStorage
        async let limits = safeStorage.jwt(decrypting: Self.encrypted)
        async let activity = safeStorage.jwt(decrypting: Self.encrypted)
        #expect(try await [limits, activity] == [CursorAccessTokenTests.jwt, CursorAccessTokenTests.jwt])
        #expect(keychain.reads == 1)
    }

    @Test("B-26 a denied read keeps nothing, so the next refresh asks again")
    func deniedReadIsAskedAgain() async throws {
        let safeStorage = self.safeStorage
        keychain.deniesAccess = true
        await #expect(throws: ProviderIssue.specific(.missingKeychainAccess)) {
            try await safeStorage.jwt(decrypting: Self.encrypted)
        }
        keychain.deniesAccess = false
        #expect(try await safeStorage.jwt(decrypting: Self.encrypted) == CursorAccessTokenTests.jwt)
        #expect(keychain.reads == 2)
    }

    @Test("B-26 a kept password that no longer opens the session is read again, as without the memo")
    mutating func changedPasswordIsReadAgain() async throws {
        let newPassword = Data("another-invented-password".utf8)
        let reencrypted = Data("v10 sealed with the new password".utf8)
        decryptor.seals[reencrypted] = .init(password: newPassword, plaintext: Data(CursorAccessTokenTests.jwt.utf8))
        let safeStorage = self.safeStorage
        _ = try await safeStorage.jwt(decrypting: Self.encrypted)

        keychain.items = [CursorSafeStorage.keychainService: newPassword]
        #expect(try await safeStorage.jwt(decrypting: reencrypted) == CursorAccessTokenTests.jwt)
        #expect(keychain.reads == 2)
    }
}
