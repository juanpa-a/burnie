import Foundation

extension Calendar {
    /// A Gregorian calendar fixed to `timeZone`, independent of the user's calendar.
    static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
