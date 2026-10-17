import Foundation

extension TimeZone {
    /// The zone most tests read local days in. A fixed identifier that always exists.
    public static let mexicoCity = TimeZone(identifier: "America/Mexico_City")!

    /// A zone with daylight saving changes. A fixed identifier that always exists.
    public static let newYork = TimeZone(identifier: "America/New_York")!
}
