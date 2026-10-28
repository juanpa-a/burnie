import BurnieInterface
import Foundation

/// A `SafeStorageDecryptor` that opens the values the test sets, and only with the test's password.
public struct FakeSafeStorageDecryptor: SafeStorageDecryptor {
    public var password: Data
    /// Each value's plaintext.
    public var plaintexts: [Data: Data]

    public init(password: Data = Data(), plaintexts: [Data: Data] = [:]) {
        self.password = password
        self.plaintexts = plaintexts
    }

    public func decrypt(_ value: Data, password: Data) -> Data? {
        password == self.password ? plaintexts[value] : nil
    }
}
