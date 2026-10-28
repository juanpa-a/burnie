import BurnieInterface
import Foundation

/// A `SecretReader` whose Keychain items, by service, the test sets, or that denies every read, as macOS does when the
/// user doesn't allow access. Counts the reads, so a test sees how often the Keychain was asked.
/// `lock` serializes `stored`, `denying` and `count`, so tasks can share it.
public final class FakeSecretReader: SecretReader, @unchecked Sendable {
    /// What a read throws while `deniesAccess` is on.
    public struct AccessDenied: Error {}

    private let lock = NSLock()
    private var stored: [String: Data]
    private var denying: Bool
    private var count = 0

    public var items: [String: Data] {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }

    public var deniesAccess: Bool {
        get { lock.withLock { denying } }
        set { lock.withLock { denying = newValue } }
    }

    /// Every read so far, denied ones included.
    public var reads: Int { lock.withLock { count } }

    public init(items: [String: Data] = [:], deniesAccess: Bool = false) {
        stored = items
        denying = deniesAccess
    }

    public func genericPassword(service: String, account: String?) throws -> Data? {
        try lock.withLock {
            count += 1
            if denying { throw AccessDenied() }
            return stored[service]
        }
    }
}
