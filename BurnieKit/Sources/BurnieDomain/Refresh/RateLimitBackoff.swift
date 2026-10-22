import Foundation

/// Wait after a 429: 1, 2, 4… minutes up to 45 for the 429s in a row, or the server's `Retry-After` when it's longer,
/// never past 45 minutes. A `Retry-After` of 0 or in the past never retries at once, and a huge one never stops the task
/// until relaunch (B-33).
public struct RateLimitBackoff: Hashable, Sendable {
    private static let longestWait: TimeInterval = 45 * 60

    private var consecutiveRateLimits = 0
    /// Nothing is requested from the task before this date, not even with the Refresh button (B-33).
    public private(set) var retryAt: Date?

    public init() {}

    public mutating func recordRateLimit(retryAt serverRetryAt: Date?, now: Date) {
        consecutiveRateLimits += 1
        let step = TimeInterval(60 << min(consecutiveRateLimits - 1, 6))
        let earliest = now.addingTimeInterval(step)
        let latest = now.addingTimeInterval(Self.longestWait)
        // A date that isn't finite counts as no `Retry-After` (D-5).
        let serverDate = serverRetryAt.flatMap { $0.timeIntervalSinceReferenceDate.isFinite ? $0 : nil } ?? earliest
        retryAt = min(max(serverDate, earliest), latest)
    }

    public mutating func reset() {
        consecutiveRateLimits = 0
        retryAt = nil
    }

    public func allowsRequest(at now: Date) -> Bool {
        retryAt.map { now >= $0 } ?? true
    }
}
