import BurnieCore
import Foundation

/// A `Clock` the test moves forward while the code under test holds it; `FixedClock` is a value, so a copy handed
/// over can't be moved anymore.
/// `lock` serializes `current`, so tasks can share it.
public final class ManualClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    public let timeZone: TimeZone

    public var now: Date { lock.withLock { current } }

    public init(now: Date, timeZone: TimeZone = .mexicoCity) {
        current = now
        self.timeZone = timeZone
    }

    public func advance(by seconds: TimeInterval) {
        lock.withLock { current.addTimeInterval(seconds) }
    }
}
