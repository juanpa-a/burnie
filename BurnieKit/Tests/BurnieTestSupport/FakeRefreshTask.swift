import BurnieDomain
import BurnieInterface
import Foundation

/// A refresh task whose outcome the test sets and whose calls it counts; `gate` holds runs while the test keeps it
/// closed.
/// `lock` serializes `outcome` and `callCount`, so tasks can share it.
public final class FakeRefreshTask: @unchecked Sendable {
    public let gate = Gate()
    private let lock = NSLock()
    private var outcome: Result<Part, ProviderIssue>
    private var callCount = 0

    /// How many runs went past the gate.
    public var calls: Int { lock.withLock { callCount } }

    public init(_ outcome: Result<Part, ProviderIssue>) {
        self.outcome = outcome
    }

    public func set(_ outcome: Result<Part, ProviderIssue>) {
        lock.withLock { self.outcome = outcome }
    }

    /// The task as a provider declares it.
    public func task(named name: String, part: PartKind, policy: RefreshPolicy, watcher: (any ActivityWatcher)? = nil) -> RefreshTask {
        RefreshTask(name: name, part: part, policy: policy, watcher: watcher) { [self] in
            await gate.pass()
            return lock.withLock {
                callCount += 1
                return outcome
            }
        }
    }
}
