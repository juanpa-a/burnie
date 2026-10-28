import BurnieInterface
import Foundation

/// A `SecretReader` whose Keychain items, by service, the test sets, or that denies every read, as macOS does when the
/// user doesn't allow access.
public struct FakeSecretReader: SecretReader {
    /// What a read throws while `deniesAccess` is on.
    public struct AccessDenied: Error {}

    public var items: [String: Data]
    public var deniesAccess: Bool

    public init(items: [String: Data] = [:], deniesAccess: Bool = false) {
        self.items = items
        self.deniesAccess = deniesAccess
    }

    public func genericPassword(service: String, account: String?) throws -> Data? {
        if deniesAccess { throw AccessDenied() }
        return items[service]
    }
}
