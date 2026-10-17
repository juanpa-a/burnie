import BurnieDomain
import Foundation

/// The status line of a row on the providers screen (B-29).
public enum StatusLine {
    /// "Off" while disabled, "{displayName} not found", "Sign-in expired · open {displayName}"; any other state, a
    /// specific issue included, shows the provider's healthy line.
    public static func text(for panel: ProviderPanel) -> String {
        let name = panel.descriptor.displayName
        guard panel.isEnabled else { return "Off" }
        switch issue(of: panel.state) {
        case .notFound?:
            return "\(name) not found"
        case .signInExpired?:
            return "Sign-in expired · open \(name)"
        default:
            let context = StatusContext(plan: panel.state.snapshot?.plan, sourceLocation: panel.sourceLocation)
            return panel.descriptor.copy.status(context)
        }
    }

    /// A total failure's issue, or a shown snapshot's partial one.
    private static func issue(of state: ProviderState) -> ProviderIssue? {
        switch state {
        case .failed(let issue): issue
        case .ready(let snapshot): snapshot.issue
        case .loading: nil
        }
    }
}
