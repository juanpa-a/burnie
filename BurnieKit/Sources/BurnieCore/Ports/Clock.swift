import Foundation

/// The core's only source of time: nothing in `BurnieCore` calls `Date()` or `TimeZone.current`.
public protocol Clock: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}
