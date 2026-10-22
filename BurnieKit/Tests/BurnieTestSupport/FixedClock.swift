import BurnieInterface
import Foundation

/// A `Clock` stopped where the test puts it.
public struct FixedClock: Clock {
    public var now: Date
    public var timeZone: TimeZone

    public init(now: Date = Gen.reference, timeZone: TimeZone = .mexicoCity) {
        self.now = now
        self.timeZone = timeZone
    }
}
