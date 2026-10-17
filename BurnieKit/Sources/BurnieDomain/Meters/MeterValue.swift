import Foundation

/// What a meter reads.
public enum MeterValue: Hashable, Sendable {
    /// "64%"
    case percent(Int)
    /// "$13.40 / $20"; without a limit, "No limit".
    case money(used: Cents, limit: Cents?)
}
