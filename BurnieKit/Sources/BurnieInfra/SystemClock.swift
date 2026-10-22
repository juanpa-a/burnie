import BurnieInterface
import Foundation

/// The system's clock and time zone: the only place below the composition root that reads them.
public struct SystemClock: Clock {
    public init() {}

    public var now: Date { Date() }
    public var timeZone: TimeZone { .current }
}
