import BurnieInterface
import Foundation

extension RuntimeState {
    /// After the switch changed it; turning it on may need the user's approval in System Settings, which opens then
    /// (B-58).
    mutating func changeLaunchAtLogin(to status: LoginItemStatus) -> [Effect] {
        launchAtLogin = status == .enabled
        return status == .requiresApproval ? [.openLoginItemsSettings] : []
    }

    /// Read again when the providers screen appears, since System Settings can change it (B-58).
    mutating func readLaunchAtLogin(_ status: LoginItemStatus) -> [Effect] {
        launchAtLogin = status == .enabled
        return []
    }

    /// The version a newer Burnie has, or nil once there's none to offer, like a skipped one (B-57).
    mutating func findUpdate(_ version: String?) -> [Effect] {
        availableUpdate = version
        return []
    }

    /// A "Check for updates" tap starts a check unless one is in flight (B-76).
    mutating func requestUpdateCheck() -> [Effect] {
        guard updateCheck == .idle else { return [] }
        updateCheck = .checking
        return [.checkUpdates]
    }

    /// What the check came back with: an update to offer (B-57 takes over from there), nothing, or a failed check that
    /// leaves the row ready to try again (B-76).
    mutating func finishUpdateCheck(_ result: UpdateCheckResult) -> [Effect] {
        switch result {
        case .found(let version):
            updateCheck = .idle
            availableUpdate = version
        case .upToDate:
            updateCheck = .upToDate
            availableUpdate = nil
        case .failed:
            updateCheck = .idle
        }
        return []
    }
}
