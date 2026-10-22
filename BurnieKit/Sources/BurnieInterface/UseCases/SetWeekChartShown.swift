import Foundation

/// The "Activity chart" switch, which shows the week chart.
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
