import Foundation

/// Checks the release feed and installs a newer Burnie when the user asks.
@MainActor
public protocol Updater {
    /// Reports the available version after each scheduled check, or nil when there's none to offer (B-57).
    func start(onUpdate: @escaping @Sendable (_ version: String?) -> Void)
    /// Opens the updater's window.
    func install()
    /// Checks the release feed now, user-initiated and quiet: the result comes back in `onResult`, no window (B-76).
    func checkForUpdates(onResult: @escaping @Sendable (UpdateCheckResult) -> Void)
}
