import BurnieCore
import Foundation

/// A limits source whose result the test controls.
/// `lock` serializes `result` and `callCount`, so tasks can share it.
public final class FakeLimitsSource: LimitsSource, @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<LimitsReading, ProviderIssue>
    private var callCount = 0

    /// How many times the source was read.
    public var calls: Int { lock.withLock { callCount } }

    public init(_ result: Result<LimitsReading, ProviderIssue>) {
        self.result = result
    }

    public func set(_ result: Result<LimitsReading, ProviderIssue>) {
        lock.withLock { self.result = result }
    }

    public func limits() async throws(ProviderIssue) -> LimitsReading {
        try lock.withLock {
            callCount += 1
            return result
        }.get()
    }
}
