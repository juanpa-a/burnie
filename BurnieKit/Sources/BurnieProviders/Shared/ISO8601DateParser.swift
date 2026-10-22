import Foundation

/// ISO 8601 dates from APIs and logs: first with fractional seconds (millis to micros), then without.
enum ISO8601DateParser {
    static func date(from string: String) -> Date? {
        (try? Date(string, strategy: withFraction)) ?? (try? Date(string, strategy: withoutFraction))
    }

    private static let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let withoutFraction = Date.ISO8601FormatStyle()
}
