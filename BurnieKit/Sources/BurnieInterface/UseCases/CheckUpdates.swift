import Foundation

/// The "Check for updates" button: checks the release feed now, quietly, and the row reports how it went in place (B-76).
public struct CheckUpdates: Sendable {
    private let action: @MainActor @Sendable () -> Void

    public init(_ action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction() {
        action()
    }
}
