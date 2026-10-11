import Foundation

public enum ProviderState: Sendable, Equatable {
    /// No cache and the first fetch in flight.
    case loading
    /// May carry a partial issue.
    case ready(UsageSnapshot)
    /// Nothing at all to show.
    case failed(ProviderIssue)
}
