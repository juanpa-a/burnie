import Foundation

/// What the UI shows for a provider: its content and a partial issue. Only numbers, dates and the plan name, never
/// secrets.
public struct UsageSnapshot: Hashable, Codable, Sendable {
    public var provider: ProviderID
    public var content: SnapshotContent
    /// A partial issue, shown inside the section instead of in place of it.
    public var issue: ProviderIssue?

    public init(provider: ProviderID, content: SnapshotContent, issue: ProviderIssue? = nil) {
        self.provider = provider
        self.content = content
        self.issue = issue
    }

    /// When the limits arrived, or without limits, when the activity arrived: the age the header reveals.
    public var fetchedAt: Date {
        switch content {
        case .limits(let view, _): view.at
        case .activityOnly(let usage): usage.at
        }
    }

    /// The limits part, if the snapshot has one.
    public var limits: LimitsPart? {
        guard case .limits(let view, _) = content else { return nil }
        return view.value
    }

    public var plan: PlanName? {
        limits?.plan
    }

    public var meters: MeterSet? {
        limits?.meters
    }

    /// None without a limits part.
    public var features: SnapshotFeatures {
        limits?.features ?? .empty
    }

    public var today: TodayUsage? {
        switch content {
        case .limits(_, let today): today
        case .activityOnly(let usage): usage.value
        }
    }
}
