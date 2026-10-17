import BurnieCore
import Foundation

/// `SecretReader` whose Keychain items, by service, the test sets.
public struct FakeSecretReader: SecretReader {
    public var items: [String: Data]

    public init(items: [String: Data] = [:]) {
        self.items = items
    }

    public func genericPassword(service: String, account: String?) throws -> Data? {
        items[service]
    }
}
