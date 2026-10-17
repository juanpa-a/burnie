// expect: none
import BurnieCore
import Foundation

/// A clock the test sets. Test support builds on BurnieCore while the legacy layout exists.
// Serialized by `lock`, which guards `current`.
public final class FixedClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 1_000_000)

    public var now: Date { lock.withLock { current } }
    public var timeZone: TimeZone { TimeZone(secondsFromGMT: 0)! }
}
