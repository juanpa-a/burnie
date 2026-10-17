import Foundation

/// Wait after a 429: honors `Retry-After`; without it, 1, 2, 4… minutes up to 60.
public struct RateLimitBackoff: Hashable, Sendable {
    private static let longestWait: TimeInterval = 60 * 60

    private var consecutiveRateLimits = 0
    /// Nothing is requested from the task before this date, not even with the Refresh button (B-33).
    public private(set) var retryAt: Date?

    public init() {}

    public mutating func recordRateLimit(retryAt serverRetryAt: Date?, now: Date) {
        consecutiveRateLimits += 1
        let minutes = 1 << min(consecutiveRateLimits - 1, 6)
        retryAt = serverRetryAt ?? now.addingTimeInterval(min(TimeInterval(minutes * 60), Self.longestWait))
    }

    public mutating func reset() {
        consecutiveRateLimits = 0
        retryAt = nil
    }

    public func allowsRequest(at now: Date) -> Bool {
        retryAt.map { now >= $0 } ?? true
    }
}
