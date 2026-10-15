import Foundation

/// Today's usage as the provider's header shows it.
public enum TodayUsage: Codable, Sendable, Equatable {
    /// "25M tokens today"
    case tokens(Int)
    /// "$12.40 today"
    case money(cents: Int)
}
