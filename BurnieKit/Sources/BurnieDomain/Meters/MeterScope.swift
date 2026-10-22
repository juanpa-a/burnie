import Foundation

/// Whose usage a meter counts: the user's own, or the whole team's, like a team plan's shared pool. The ring follows
/// only a primary meter of the user's own (B-53).
public enum MeterScope: Hashable, Sendable {
    case own
    case team
}
