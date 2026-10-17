import Foundation

extension UsageSnapshot {
    /// Stale data beats a gap: when `next` has no limits part and `previous` has one, the result keeps `previous`'s
    /// stamped limits part (plan, meters, unit and features, with their age) and takes today's usage, the issue and the
    /// provider from `next`. Otherwise it is `next` (B-17).
    ///
    /// A semigroup, right-biased: the last snapshot with limits wins the limits, and the limits part is never split.
    public static func merge(_ previous: UsageSnapshot, _ next: UsageSnapshot) -> UsageSnapshot {
        guard case .activityOnly(let usage) = next.content, case .limits(let view, _) = previous.content else { return next }
        return UsageSnapshot(provider: next.provider, content: .limits(view: view, today: usage.value), issue: next.issue)
    }
}
