import BurnieInterface
import Foundation

/// A `SafeStorageDecryptor` that opens each value the test sealed, and only with the password it was sealed with.
public struct FakeSafeStorageDecryptor: SafeStorageDecryptor {
    /// What a sealed value opens to, and the password that opens it.
    public struct Seal: Sendable {
        public let password: Data
        public let plaintext: Data

        public init(password: Data, plaintext: Data) {
            self.password = password
            self.plaintext = plaintext
        }
    }

    public var seals: [Data: Seal]

    public init(seals: [Data: Seal] = [:]) {
        self.seals = seals
    }

    public func decrypt(_ value: Data, password: Data) -> Data? {
        guard let seal = seals[value], seal.password == password else { return nil }
        return seal.plaintext
    }
}
