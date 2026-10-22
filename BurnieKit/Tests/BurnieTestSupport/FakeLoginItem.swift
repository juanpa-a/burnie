import BurnieInterface
import Foundation

/// A `LoginItem` whose status the test sets; setting it on answers `whenEnabled`, as macOS may want approval first.
@MainActor
public final class FakeLoginItem: LoginItem {
    public var current: LoginItemStatus
    public var whenEnabled: LoginItemStatus
    public private(set) var settingsOpened = 0

    public init(status: LoginItemStatus = .disabled, whenEnabled: LoginItemStatus = .enabled) {
        current = status
        self.whenEnabled = whenEnabled
    }

    public func status() -> LoginItemStatus {
        current
    }

    public func set(_ enabled: Bool) {
        current = enabled ? whenEnabled : .disabled
    }

    public func openSystemSettings() {
        settingsOpened += 1
    }
}
