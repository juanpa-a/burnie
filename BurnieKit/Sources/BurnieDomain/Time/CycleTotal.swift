import Foundation

/// One provider's tokens over its current cycle (B-79): from the local day the cycle starts on, or from the first day
/// of its unbroken history when that's later, through today.
public struct CycleTotal: Hashable, Sendable {
    /// The first day counted.
    public let since: LocalDay
    public let tokens: Tokens

    /// nil when the history has no day of the cycle: the provider hasn't recorded any, or not since the cycle started.
    public static func make(history: UsageHistory, provider: ProviderID, cycleStart: LocalDay, today: LocalDay) -> CycleTotal? {
        guard let recorded = history.recordedSince(for: provider) else { return nil }
        let since = max(cycleStart, recorded)
        guard since <= today else { return nil }
        return CycleTotal(since: since, tokens: history.total(for: provider, from: since, through: today))
    }
}
