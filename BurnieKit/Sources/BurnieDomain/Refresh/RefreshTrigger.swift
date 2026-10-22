import Foundation

/// Why a refresh is requested.
public enum RefreshTrigger: Hashable, Sendable {
    case timer
    case popoverOpened
    /// The Refresh button, a sign-in renewal, or a provider turned on: ignores the data's age.
    case manual
    case wake
    case networkRestored
    /// The provider's activity watcher saw a change.
    case activityChanged
}
