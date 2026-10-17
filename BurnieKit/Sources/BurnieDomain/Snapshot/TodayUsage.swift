import Foundation

/// Today's usage as a provider's header shows it.
public enum TodayUsage: Hashable, Sendable {
    /// "25M tokens today"
    case tokens(Tokens)
    /// "$12.40 today"
    case money(Cents)
}
