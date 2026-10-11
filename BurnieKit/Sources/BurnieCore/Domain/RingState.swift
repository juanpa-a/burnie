import Foundation

/// What the menu bar icon shows.
public enum RingState: Sendable, Equatable {
    /// The flame alone.
    case hidden
    /// The flame inside a ring filled to the favorite's first meter, rounded to a whole percent.
    case visible(ProviderID, fraction: Double)
}
