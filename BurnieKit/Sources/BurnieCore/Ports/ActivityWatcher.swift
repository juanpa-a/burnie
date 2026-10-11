import Foundation

/// Reports when a provider's local activity changes (FSEvents on Claude's logs).
public protocol ActivityWatcher: Sendable {
    func start(onChange: @escaping @Sendable () -> Void)
    func stop()
}
