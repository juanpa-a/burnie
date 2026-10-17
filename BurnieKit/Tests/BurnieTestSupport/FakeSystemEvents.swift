import BurnieCore
import Foundation

/// `SystemEvents` the test drives: it keeps the wake callback it's started with and calls it when the test says.
/// It never reports a network change: the scheduler's tests set it online or offline themselves.
@MainActor
public final class FakeSystemEvents: SystemEvents {
    private var onWake: (@Sendable () -> Void)?

    public init() {}

    public func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void) {
        self.onWake = onWake
    }

    /// Calls the wake callback, as the Mac waking up would.
    public func wake() {
        onWake?()
    }
}
