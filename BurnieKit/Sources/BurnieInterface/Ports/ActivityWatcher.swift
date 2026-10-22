import Foundation

/// Reports when local activity changes in the directories it was built for.
public protocol ActivityWatcher: Sendable {
    func start(onChange: @escaping @Sendable () -> Void)
    func stop()
}
