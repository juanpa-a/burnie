// expect: none
import AppKit
import BurnieCore
import Foundation
import os

/// The real clock. BurnieSystem counts as Infra, so it may read the system time and time zone.
public struct SystemClock: Clock {
    private let logger = Logger(subsystem: "dev.example.burnie", category: "clock")

    public init() {}

    public var now: Date { Date() }
    public var timeZone: TimeZone { TimeZone.current }

    public func measure(_ work: () -> Void) -> Duration {
        let started = ContinuousClock.now
        work()
        return ContinuousClock.now - started
    }
}
