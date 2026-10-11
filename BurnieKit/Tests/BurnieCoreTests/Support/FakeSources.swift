import Foundation
@testable import BurnieCore

/// A limits source whose result the test controls.
final class FakeLimitsSource: LimitsSource, @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<LimitsReading, ProviderIssue>
    private(set) var calls = 0

    init(_ result: Result<LimitsReading, ProviderIssue>) {
        self.result = result
    }

    func set(_ result: Result<LimitsReading, ProviderIssue>) {
        lock.withLock { self.result = result }
    }

    func limits() async throws(ProviderIssue) -> LimitsReading {
        try lock.withLock {
            calls += 1
            return result
        }.get()
    }
}

/// An activity source whose result the test controls.
final class FakeActivitySource: ActivitySource, @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<[LocalDay: Int], ProviderIssue>
    private(set) var calls = 0

    init(_ result: Result<[LocalDay: Int], ProviderIssue>) {
        self.result = result
    }

    func set(_ result: Result<[LocalDay: Int], ProviderIssue>) {
        lock.withLock { self.result = result }
    }

    func dailyTokens() async throws(ProviderIssue) -> [LocalDay: Int] {
        try lock.withLock {
            calls += 1
            return result
        }.get()
    }
}
