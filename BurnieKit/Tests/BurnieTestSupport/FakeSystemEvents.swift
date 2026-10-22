import BurnieInterface
import Foundation

/// `SystemEvents` the test drives: it wakes the Mac and moves the network when told.
@MainActor
public final class FakeSystemEvents: SystemEvents {
    private var onWake: (@Sendable () -> Void)?
    private var onNetworkChange: (@Sendable (Bool) -> Void)?

    public private(set) var starts = 0

    public init() {}

    public func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void) {
        starts += 1
        self.onWake = onWake
        self.onNetworkChange = onNetworkChange
    }

    public func wake() {
        onWake?()
    }

    public func setOnline(_ isOnline: Bool) {
        onNetworkChange?(isOnline)
    }
}
