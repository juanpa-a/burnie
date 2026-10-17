
import Foundation

/// The "Ring in menu bar" switch.
public struct SetRingShown: Sendable {
    private let action: @MainActor @Sendable (Bool) -> Void

    public init(_ action: @escaping @MainActor @Sendable (Bool) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ isShown: Bool) {
        action(isShown)
    }
}
