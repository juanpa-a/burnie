import Foundation

/// Why a refresh is requested.
public enum RefreshTrigger: Sendable {
    case timer
    case popoverOpened
    /// Refresh button: ignores the data's age.
    case manual
    case wake
    case networkRestored
    /// FSEvents on the local logs.
    case activityChanged
}
