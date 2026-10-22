import Foundation

/// What macOS reports for launch at login.
public enum LoginItemStatus: Hashable, Sendable {
    case enabled
    case disabled
    /// Waiting for the user's approval in System Settings.
    case requiresApproval
}
