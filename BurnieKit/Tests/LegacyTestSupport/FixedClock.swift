import BurnieCore
import Foundation

/// A `Clock` stopped where the test puts it; tests move it by setting `now` or `timeZone`.
public struct FixedClock: Clock {
    public var now: Date
    public var timeZone: TimeZone

    public init(now: Date, timeZone: TimeZone = .mexicoCity) {
        self.now = now
        self.timeZone = timeZone
    }
}
