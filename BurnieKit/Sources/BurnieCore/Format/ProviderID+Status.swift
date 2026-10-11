import Foundation

extension ProviderID {
    /// The status line of each row on the providers screen.
    /// `sourceLocation` is where Claude reads from ("~/.claude"); Cursor shows its plan.
    public func statusText(isEnabled: Bool, state: ProviderState?, sourceLocation: String?) -> String {
        guard isEnabled else { return "Off" }
        switch Self.issue(in: state) {
        case .notFound?:
            return "\(displayName) not found"
        case .signInExpired?:
            return "Sign-in expired · open \(displayName)"
        default:
            return healthyStatus(plan: Self.snapshot(in: state)?.plan, sourceLocation: sourceLocation)
        }
    }

    private func healthyStatus(plan: String?, sourceLocation: String?) -> String {
        switch self {
        case .claude:
            return "Reading local logs · \(sourceLocation ?? "~/.claude")"
        case .cursor:
            // The chip is uppercase ("PRO+"); here it reads as a name: "Pro+ plan".
            return plan.map { "Signed in · \($0.capitalized) plan" } ?? "Signed in"
        }
    }

    private static func issue(in state: ProviderState?) -> ProviderIssue? {
        switch state {
        case .failed(let issue)?: issue
        case .ready(let snapshot)?: snapshot.issue
        case .loading?, nil: nil
        }
    }

    private static func snapshot(in state: ProviderState?) -> UsageSnapshot? {
        guard case .ready(let snapshot)? = state else { return nil }
        return snapshot
    }
}
