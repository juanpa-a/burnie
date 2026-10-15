import Foundation

/// A provider built from two sources: limits (network) and activity (logs or events).
///
/// Remembers the latest result of each source to compose the snapshot without refetching what wasn't refreshed.
/// If limits fail but there's activity, the snapshot arrives without meters and with the issue; the store
/// then keeps the previous meters. If there's nothing to show, it throws.
public actor CompositeUsageProvider: UsageProvider {
    public nonisolated let id: ProviderID

    private let limitsSource: LimitsSource
    private let activitySource: ActivitySource
    private let clock: Clock
    private var limits: (result: Result<LimitsReading, ProviderIssue>, fetchedAt: Date)?
    private var activity: (result: Result<ActivityReading, ProviderIssue>, fetchedAt: Date)?
    /// From the latest limits that arrived, so a failed refresh doesn't flip today's money back to tokens.
    private var unit = UsageUnit.tokens

    public init(id: ProviderID, limits: LimitsSource, activity: ActivitySource, clock: Clock) {
        self.id = id
        limitsSource = limits
        activitySource = activity
        self.clock = clock
    }

    public func snapshot(refreshing sources: Set<UsageSource>) async throws(ProviderIssue) -> UsageSnapshot {
        if sources.contains(.limits) {
            limits = (await result { () async throws(ProviderIssue) in try await limitsSource.limits() }, clock.now)
            if case .success(let reading)? = limits?.result {
                unit = reading.unit
            }
        }
        if sources.contains(.activity) {
            activity = (await result { () async throws(ProviderIssue) in try await activitySource.activity() }, clock.now)
        }
        return try composedSnapshot()
    }

    public func history(days: Int) throws(ProviderIssue) -> [DailyPoint] {
        let tokens = try loadedActivity().tokens
        return (today.advanced(by: 1 - days)...today).map { DailyPoint(day: $0, value: tokens[$0, default: 0]) }
    }

    private func composedSnapshot() throws(ProviderIssue) -> UsageSnapshot {
        let usage = (try? loadedActivity()).map(todayUsage(in:))
        if case let (.success(reading), fetchedAt)? = limits {
            return UsageSnapshot(provider: id, fetchedAt: fetchedAt, plan: reading.plan, today: usage, meters: reading.meters)
        }
        // Without meters there's only something to show if there's activity.
        guard let usage, let activity else {
            throw limitsIssue ?? activityIssue ?? .notFound
        }
        return UsageSnapshot(provider: id, fetchedAt: activity.fetchedAt, today: usage, issue: limitsIssue)
    }

    /// Money when the plan has a dollar budget and the source added up today's spend; tokens otherwise.
    private func todayUsage(in activity: ActivityReading) -> TodayUsage {
        if unit == .money, let cents = activity.spentCents[today] {
            return .money(cents: cents)
        }
        return .tokens(activity.tokens[today, default: 0])
    }

    /// The latest activity. Before it loads there's nothing to show yet.
    private func loadedActivity() throws(ProviderIssue) -> ActivityReading {
        guard let activity else { throw .notFound }
        return try activity.result.get()
    }

    private var limitsIssue: ProviderIssue? {
        if case .failure(let issue)? = limits?.result { issue } else { nil }
    }

    private var activityIssue: ProviderIssue? {
        if case .failure(let issue)? = activity?.result { issue } else { nil }
    }

    private var today: LocalDay {
        LocalDay(clock.now, in: clock.timeZone)
    }

    private func result<Value>(_ fetch: () async throws(ProviderIssue) -> Value) async -> Result<Value, ProviderIssue> {
        do {
            return .success(try await fetch())
        } catch {
            return .failure(error)
        }
    }
}
