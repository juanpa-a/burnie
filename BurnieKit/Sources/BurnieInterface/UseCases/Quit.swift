
import Foundation

/// The footer's Quit, ⌘Q.
public struct Quit: Sendable {
    private let action: @MainActor @Sendable () -> Void

    public init(_ action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction() {
        action()
    }
}
