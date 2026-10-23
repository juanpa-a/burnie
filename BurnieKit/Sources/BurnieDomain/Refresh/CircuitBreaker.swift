import Foundation

/// What stops a job its service keeps answering with something Burnie can't use: three unexpected issues in a row trip
/// it, and while it's tripped only Refresh runs the job; any other outcome resets it (B-81). The issues that wait for
/// the user, a 429 and offline don't count: each already slows the job down in its own way.
public struct CircuitBreaker: Hashable, Sendable {
    private static let unexpectedToTrip = 3

    /// Counted no further than what trips the breaker, so a tripped one is always the same value.
    private var unexpectedInARow = 0

    public init() {}

    public var isTripped: Bool {
        unexpectedInARow == Self.unexpectedToTrip
    }

    /// An unexpected issue counts one more in a row; any other outcome resets the breaker, tripped or not.
    public mutating func record<Value>(_ outcome: Result<Value, ProviderIssue>) {
        switch outcome {
        case .failure(.unexpectedResponse):
            unexpectedInARow = min(unexpectedInARow + 1, Self.unexpectedToTrip)
        case .success, .failure(.notFound), .failure(.signInExpired), .failure(.specific), .failure(.rateLimited), .failure(.offline):
            unexpectedInARow = 0
        }
    }
}
