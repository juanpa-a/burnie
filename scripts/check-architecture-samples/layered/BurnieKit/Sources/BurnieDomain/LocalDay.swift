// expect: none
import Foundation

/// A calendar day in a time zone the caller passes, never from `Date()` or `TimeZone.current`.
public struct LocalDay: Hashable, Sendable, Codable {
    public let iso: String

    public init(year: Int, month: Int, day: Int) {
        iso = String(format: "%04d-%02d-%02d", year, month, day)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let iso = try container.decode(String.self)
        guard iso.count == 10 else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not a yyyy-MM-dd day: \(iso)"))
        }
        self.iso = iso
    }

    // A fixed identifier that always exists.
    static let utc = TimeZone(identifier: "UTC")!
}
