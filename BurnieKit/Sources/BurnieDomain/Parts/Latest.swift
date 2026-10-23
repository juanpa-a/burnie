import Foundation

/// The most recent outcome of one part kind: a stamped success, or a failure with its moment and the last success, if
/// any. A success never lacks its own stamp.
public enum Latest<Value> {
    case success(Stamped<Value>)
    case failure(ProviderIssue, at: Date, lastSuccess: Stamped<Value>?)

    /// The first outcome of a part kind.
    public init(_ outcome: Result<Value, ProviderIssue>, at date: Date) {
        switch outcome {
        case .success(let value): self = .success(Stamped(value, at: date))
        case .failure(let issue): self = .failure(issue, at: date, lastSuccess: nil)
        }
    }

    /// The only way forward: a success replaces everything, and a failure keeps the last success.
    public func recording(_ outcome: Result<Value, ProviderIssue>, at date: Date) -> Latest {
        guard case .failure(let issue) = outcome else { return Latest(outcome, at: date) }
        return .failure(issue, at: date, lastSuccess: lastSuccess)
    }

    /// The most recent success, even under a later failure.
    public var lastSuccess: Stamped<Value>? {
        switch self {
        case .success(let value): value
        case .failure(_, _, let lastSuccess): lastSuccess
        }
    }

    /// The failure's issue, or nil when the latest outcome succeeded.
    public var issue: ProviderIssue? {
        guard case .failure(let issue, _, _) = self else { return nil }
        return issue
    }
}

extension Latest: Equatable where Value: Equatable {}
extension Latest: Sendable where Value: Sendable {}
