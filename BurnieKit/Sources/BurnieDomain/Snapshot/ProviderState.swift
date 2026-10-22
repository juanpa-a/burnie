import Foundation

/// What a provider's section shows.
public enum ProviderState: Hashable, Sendable {
    /// No data yet: no cache, and the first refresh hasn't answered.
    case loading
    /// A snapshot, maybe with a partial issue.
    case ready(UsageSnapshot)
    /// Nothing at all to show, only the issue.
    case failed(ProviderIssue)

    /// A total failure: over a shown snapshot, that snapshot with the issue on top; without one, the failure alone
    /// (B-18).
    public static func failing(_ issue: ProviderIssue, previous: UsageSnapshot?) -> ProviderState {
        guard var shown = previous else { return .failed(issue) }
        shown.issue = issue
        return .ready(shown)
    }

    public var snapshot: UsageSnapshot? {
        guard case .ready(let snapshot) = self else { return nil }
        return snapshot
    }

    /// The state without the features the user switched off (B-40).
    public func hiding(_ toggles: Set<FeatureToggle>) -> ProviderState {
        guard case .ready(let snapshot) = self else { return self }
        return .ready(snapshot.hiding(toggles))
    }
}
