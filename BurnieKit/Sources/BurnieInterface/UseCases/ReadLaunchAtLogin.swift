import Foundation

/// Reads launch at login again when the providers screen appears, since System Settings can change it (B-58).
public struct ReadLaunchAtLogin: Sendable {
    private let action: @MainActor @Sendable () -> Void

    public init(_ action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction() {
        action()
    }
}
