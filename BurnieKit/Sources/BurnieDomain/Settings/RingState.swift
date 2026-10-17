import Foundation

/// What the menu bar icon shows.
public enum RingState: Hashable, Sendable {
    /// The flame alone.
    case hidden
    /// The flame inside a ring filled to the favorite's primary meter, in whole percents (0…100).
    case visible(ProviderID, percent: Int)
}
