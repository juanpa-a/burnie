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
    /// Cursor's Keychain item.
    static let secrets = FakeSecretReader(items: [CursorSafeStorage.keychainService: password])
    /// Opens the fixture with `password`; the real decryption is `CommonCryptoSafeStorageDecryptor`'s, tested in Infra.
    static let decryptor = FakeSafeStorageDecryptor(
        password: password,
        plaintexts: [encrypted: Data(CursorAccessTokenTests.jwt.utf8)]
    )

    var secrets = Self.secrets
    var decryptor = Self.decryptor

    func jwt() throws(ProviderIssue) -> String {
        try CursorSafeStorage(secrets: secrets, decryptor: decryptor).jwt(decrypting: Self.encrypted)
    }

    @Test("B-26 an encrypted session opens with Cursor's Keychain item")
    func opensWithCursorsKeychainItem() throws {
        #expect(CursorSafeStorage.keychainService == "Cursor Safe Storage")
        #expect(CursorSafeStorage.keychainAccount == "Cursor")
        #expect(try jwt() == CursorAccessTokenTests.jwt)
    }

    @Test("B-26 without Cursor's Keychain item, Burnie needs Keychain access")
    mutating func missingKeychainItemNeedsKeychainAccess() {
        secrets.items = [:]
        #expect(throws: ProviderIssue.specific(.missingKeychainAccess)) { try jwt() }
    }

    @Test("B-26 a denied Keychain read needs Keychain access")
    mutating func deniedKeychainReadNeedsKeychainAccess() {
        secrets.deniesAccess = true
        #expect(throws: ProviderIssue.specific(.missingKeychainAccess)) { try jwt() }
    }

    @Test("B-26 a session the Keychain password doesn't open is unexpected")
    mutating func wrongPasswordIsUnexpected() {
        secrets.items = [CursorSafeStorage.keychainService: Data("another-password".utf8)]
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor's encrypted session can't be decrypted")) { try jwt() }
    }

    @Test("B-26 a session that doesn't open to text is unexpected")
    mutating func binaryPlaintextIsUnexpected() {
        decryptor.plaintexts = [Self.encrypted: Data([0xFF, 0xFE, 0x00])]
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor's encrypted session can't be decrypted")) { try jwt() }
    }
}
