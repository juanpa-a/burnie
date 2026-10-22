import Foundation

extension Date {
    /// Unix milliseconds as text, the way the Cursor dashboard takes dates.
    var unixMillisecondsString: String {
        String(Int64(timeIntervalSince1970 * 1_000))
    }
}
