import Foundation
import Testing
@testable import BurnieInfra

struct CommonCryptoSafeStorageDecryptorTests {
    static let password = Data("invented-safe-storage-password".utf8)
    /// "an invented Cursor session", sealed with `password` as Chromium's OSCrypt does on macOS, by a separate tool
    /// (Python's PBKDF2 and the `openssl` command), so the test doesn't check the adapter against itself.
    static let sealed = Data(base64Encoded: "djEwyOdZXaU7xgR0xMGIRWj+WhMJPfhYJFa65vvnmM+yvd4=")!

    let decryptor = CommonCryptoSafeStorageDecryptor()

    @Test func opensAValueSealedWithTheAppsPassword() {
        #expect(decryptor.decrypt(Self.sealed, password: Self.password) == Data("an invented Cursor session".utf8))
    }

    @Test func aWrongPasswordOpensNothing() {
        #expect(decryptor.decrypt(Self.sealed, password: Data("another-password".utf8)) == nil)
    }

    @Test("a value that isn't safe storage, or whose ciphertext is damaged, opens nothing", arguments: [
        Data(), Data("v10".utf8), Self.sealed.dropFirst(3), Self.sealed.dropLast(1), Self.sealed.dropLast(16),
    ])
    func opensNothingButASealedValue(value: Data) {
        #expect(decryptor.decrypt(value, password: Self.password) == nil)
    }
}
