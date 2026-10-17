
import Foundation

/// The "Last 7 days" switch.
public struct SetWeekChartShown: Sendable {
    private let action: @MainActor @Sendable (Bool) -> Void

    public init(_ action: @escaping @MainActor @Sendable (Bool) -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ isShown: Bool) {
        action(isShown)
    }
}
