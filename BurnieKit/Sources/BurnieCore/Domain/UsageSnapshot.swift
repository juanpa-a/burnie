import Foundation

/// What the UI shows for a provider. Only numbers, dates and the plan name: never secrets.
public struct UsageSnapshot: Codable, Sendable, Equatable {
    public var provider: ProviderID
    /// When the meters arrived; without meters, when the activity arrived.
    public var fetchedAt: Date
    /// "MAX", "PRO"; nil hides the chip.
    public var plan: String?
    /// nil if the activity source failed.
    public var today: TodayUsage?
    /// In render order; empty if the limits source failed.
    public var meters: [Meter]
    /// Partial failure: shown inside the section, not instead of it.
    public var issue: ProviderIssue?

    public init(
        provider: ProviderID,
        fetchedAt: Date,
        plan: String? = nil,
        today: TodayUsage? = nil,
        meters: [Meter] = [],
        issue: ProviderIssue? = nil
    ) {
        self.provider = provider
        self.fetchedAt = fetchedAt
        self.plan = plan
        self.today = today
        self.meters = meters
        self.issue = issue
    }
}
