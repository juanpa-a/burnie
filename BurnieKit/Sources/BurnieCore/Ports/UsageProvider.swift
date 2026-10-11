import Foundation

/// The only thing the store knows about a provider.
public protocol UsageProvider: Sendable {
    var id: ProviderID { get }

    /// Refreshes `sources` and composes the snapshot from the latest result of each source.
    /// A total failure throws; a partial one travels in `UsageSnapshot.issue`.
    func snapshot(refreshing sources: Set<UsageSource>) async throws(ProviderIssue) -> UsageSnapshot

    /// The `days` local days ending today, from the latest loaded activity; days without data are 0.
    /// Throws the activity source's issue if there's no activity to show.
    func history(days: Int) async throws(ProviderIssue) -> [DailyPoint]
}
