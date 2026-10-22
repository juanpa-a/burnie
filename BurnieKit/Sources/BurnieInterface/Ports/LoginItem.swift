import Foundation

/// Launch at login, which macOS owns.
@MainActor
public protocol LoginItem {
    func status() -> LoginItemStatus
    func set(_ enabled: Bool)
    /// Opens the Login Items pane of System Settings, where the user approves.
    func openSystemSettings()
}
