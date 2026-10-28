import Foundation

/// What a user-initiated check of the release feed came back with (B-76).
public enum UpdateCheckResult: Equatable, Sendable {
    /// A newer Burnie is on the feed.
    case found(String)
    case upToDate
    /// The feed couldn't be reached or read.
    case failed
}
