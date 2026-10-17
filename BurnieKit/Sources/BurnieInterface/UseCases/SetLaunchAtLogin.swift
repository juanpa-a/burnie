
import Foundation

/// The "Launch at login" switch; when macOS wants the user's approval, System Settings opens (B-58).
public struct SetLaunchAtLogin: Sendable {
    private let action: @MainActor @Sendable (Bool) -> Void

    public init(_ action: @escaping @MainActor @Sendable (Bool) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ isEnabled: Bool) {
        action(isEnabled)
    }
}
