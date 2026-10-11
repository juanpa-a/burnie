import Foundation

extension UsageSnapshot {
    /// Stale data beats a gap: if this snapshot arrived without meters, it keeps `cached`'s meters
    /// with their plan and `fetchedAt`, so the age the header reveals is the meters' age.
    public func keepingMeters(of cached: UsageSnapshot?) -> UsageSnapshot {
        guard meters.isEmpty, let cached, !cached.meters.isEmpty else { return self }
        var merged = self
        merged.meters = cached.meters
        merged.plan = cached.plan
        merged.fetchedAt = cached.fetchedAt
        return merged
    }

    /// The cached snapshot with a total failure's problem on top.
    public func with(issue: ProviderIssue) -> UsageSnapshot {
        var snapshot = self
        snapshot.issue = issue
        return snapshot
    }
}
