// expect: none
import BurnieDomain
import BurnieInterface
import Foundation

// Serialized by `lock`, which guards `current`.
public final class FixedClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    public let timeZone: TimeZone

    public init(now: Date, timeZone: TimeZone) {
        current = now
        self.timeZone = timeZone
    }

    public var now: Date { lock.withLock { current } }
}
