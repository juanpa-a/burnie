import Foundation
@testable import BurnieCore

struct FixedClock: Clock {
    var now: Date
    var timeZone: TimeZone = .mexicoCity
}

extension Date {
    /// A test's ISO 8601 date; fails the test instead of returning nil.
    static func iso(_ string: String) -> Date {
        try! Date(string, strategy: .iso8601)
    }
}

extension TimeZone {
    static let mexicoCity = TimeZone(identifier: "America/Mexico_City")!
    static let newYork = TimeZone(identifier: "America/New_York")!
}

extension Locale {
    static let enUS = Locale(identifier: "en_US")
}

extension LocalDay {
    static func day(_ iso: String) -> LocalDay {
        LocalDay(iso: iso)!
    }
}
