import Foundation

extension UsageSnapshot {
    /// The snapshot a provider's latest limits and activity make, or the issue of a total failure: never loading.
    ///
    /// - Limits that succeeded give the meters, stamped when they arrived, with today's usage if the activity
    ///   succeeded and no issue, even when the activity failed (B-10, B-13, B-16).
    /// - Without them, a successful activity gives today's usage alone, stamped when it arrived, with the limits' issue
    ///   (B-12, B-15). Failed limits never bring back their last meters here: merge does (B-17).
    /// - With neither, the limits' issue, else the activity's, else not found (B-14).
    public static func compose(
        provider: ProviderID,
        limits: Latest<LimitsPart>?,
        activity: Latest<ActivityPart>?,
        today: LocalDay
    ) -> Result<UsageSnapshot, ProviderIssue> {
        let usage: Stamped<TodayUsage>? = if case .success(let part)? = activity {
            part.map { $0.usage(on: today) }
        } else {
            nil
        }
        if case .success(let view)? = limits {
            return .success(UsageSnapshot(provider: provider, content: .limits(view: view, today: usage?.value)))
        }
        guard let usage else {
            return .failure(limits?.issue ?? activity?.issue ?? .notFound)
        }
        return .success(UsageSnapshot(provider: provider, content: .activityOnly(usage), issue: limits?.issue))
    }
}
