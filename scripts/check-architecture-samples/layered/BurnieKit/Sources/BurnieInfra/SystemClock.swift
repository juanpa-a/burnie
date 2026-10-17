// expect: none
import BurnieInterface
import Foundation
import os

/// The real clock: Infra may read the system time, time zone and locale, and log with os.Logger.
public struct SystemClock: Clock {
    private static let logger = Logger(subsystem: "dev.example.burnie", category: "clock")

    public init() {}

    public var now: Date { Date() }
    public var timeZone: TimeZone { TimeZone.current }
    public var locale: Locale { Locale.current }
    public var uptime: ContinuousClock.Instant { ContinuousClock.now }
}
