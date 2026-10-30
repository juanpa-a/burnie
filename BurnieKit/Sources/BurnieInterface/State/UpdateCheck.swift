import Foundation

/// The "Check for updates" row's phase (B-82); while a newer Burnie is available the Update row takes over (B-57).
public enum UpdateCheck: Equatable, Sendable {
    /// Ready to check.
    case idle
    /// A check is in flight.
    case checking
    /// The last check found no newer Burnie.
    case upToDate
}
