import Foundation

/// The only source of `now` and the time zone: nothing below the composition root reads the system clock.
public protocol Clock: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}
