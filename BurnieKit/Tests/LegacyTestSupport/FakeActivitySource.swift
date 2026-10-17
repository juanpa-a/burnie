import BurnieCore
import Foundation

/// An activity source whose result the test controls. Its `gate` holds reads while the test keeps it closed;
/// a held read returns the result that's set when the gate lets it through.
/// `lock` serializes `result` and `callCount`, so tasks can share it.
public final class FakeActivitySource: ActivitySource, @unchecked Sendable {
    public let gate = Gate()
    private let lock = NSLock()
    private var result: Result<ActivityReading, ProviderIssue>
    private var callCount = 0

    /// How many times the source was read.
    public var calls: Int { lock.withLock { callCount } }

    public init(_ result: Result<ActivityReading, ProviderIssue>) {
        self.result = result
    }

    public func set(_ result: Result<ActivityReading, ProviderIssue>) {
        lock.withLock { self.result = result }
    }

    public func activity() async throws(ProviderIssue) -> ActivityReading {
        await gate.pass()
        return try lock.withLock {
            callCount += 1
            return result
        }.get()
    }
}
