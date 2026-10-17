
import Foundation

/// The Refresh button: every enabled task regardless of age, except during a backoff (B-33). Returns once every run it
/// started finished.
public struct RefreshUsage: Sendable {
    private let action: @MainActor @Sendable () async -> Void

    public init(_ action: @escaping @MainActor @Sendable () async -> Void) {
        self.action = action
    }

    @MainActor
    public func callAsFunction() async {
        await action()
    }
}
