// expect: none
import BurnieDomain
import Foundation

/// The only source of now and of the time zone.
public protocol Clock: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}
