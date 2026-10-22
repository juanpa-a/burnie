import Foundation

/// Opening the popover refreshes what is stale. Both open signals arrive together, debounced to one within 1 s;
/// its refresh shows the spinner (B-39, B-59).
public struct OpenPopover: Sendable {
    private let action: @MainActor @Sendable () -> Void

    public init(_ action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction() {
        action()
    }
}
