import Foundation

extension Date {
    /// A test's literal ISO 8601 date, like `.iso("2026-10-10T20:00:00Z")`; a typo stops the run instead of returning nil.
    public static func iso(_ string: String) -> Date {
        guard let date = try? Date(string, strategy: .iso8601) else { fatalError("Not an ISO 8601 date: \(string)") }
        return date
    }
}
