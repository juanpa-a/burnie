import BurnieCore
import Foundation

/// An `ActivityWatcher` that counts its starts and stops and reports a change when the test says, as FSEvents would
/// after new log lines.
/// `lock` serializes `onChange`, `startCount` and `stopCount`, so tasks can share it.
public final class FakeActivityWatcher: ActivityWatcher, @unchecked Sendable {
    private let lock = NSLock()
    private var onChange: (@Sendable () -> Void)?
    private var startCount = 0
    private var stopCount = 0

    public var starts: Int { lock.withLock { startCount } }
    public var stops: Int { lock.withLock { stopCount } }

    public init() {}

    public func start(onChange: @escaping @Sendable () -> Void) {
        lock.withLock {
            startCount += 1
            self.onChange = onChange
        }
    }

    public func stop() {
        lock.withLock {
            stopCount += 1
            onChange = nil
        }
    }

    /// Calls the `onChange` of the latest start; while stopped, nothing hears it.
    public func reportChange() {
        lock.withLock { onChange }?()
    }
}
