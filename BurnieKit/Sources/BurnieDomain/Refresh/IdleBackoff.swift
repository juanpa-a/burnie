import Foundation

/// The longer timer while a job waits for the user: each not found, sign-in expired or specific issue in a row doubles
/// its interval, up to 45 minutes or the interval itself when that's longer; any other outcome resets it. Only the timer
/// waits longer: the popover, Refresh, wake and network restored still run the job (B-35).
public struct IdleBackoff: Hashable, Sendable {
    private static let longestInterval: TimeInterval = 45 * 60
    /// Six doublings take any interval past 45 minutes, so counting further changes nothing.
    private static let mostDoublings = 6

    private var doublings = 0

    public init() {}

    /// An issue only the user can fix doubles the interval once more; any other outcome resets it.
    public mutating func record<Value>(_ outcome: Result<Value, ProviderIssue>) {
        switch outcome {
        case .failure(.notFound), .failure(.signInExpired), .failure(.specific):
            doublings = min(doublings + 1, Self.mostDoublings)
        case .success, .failure(.rateLimited), .failure(.offline), .failure(.unexpectedResponse):
            doublings = 0
        }
    }

    public func stretch(_ interval: TimeInterval) -> TimeInterval {
        guard doublings > 0 else { return interval }
        return max(interval, min(interval * TimeInterval(1 << doublings), Self.longestInterval))
    }
}
