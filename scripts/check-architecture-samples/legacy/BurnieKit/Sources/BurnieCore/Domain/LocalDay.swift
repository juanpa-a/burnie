// expect: none
import Foundation

/// A calendar day. Never built from `Date()` or `TimeZone.current`: the caller passes the time zone.
public struct LocalDay: Hashable, Sendable {
    public let iso: String

    public func start(in calendar: Calendar) -> Date {
        // `iso` always holds a valid yyyy-MM-dd, which every Gregorian calendar can resolve.
        calendar.date(from: components)!
    }

    // A fixed identifier that always exists.
    private static let utc = TimeZone(identifier: "UTC")!

    private var components: DateComponents { DateComponents() }
}
