import Foundation

/// Reports when the Mac wakes up and when the network comes and goes.
@MainActor
public protocol SystemEvents {
    func start(onWake: @escaping @Sendable () -> Void, onNetworkChange: @escaping @Sendable (_ isOnline: Bool) -> Void)
}
