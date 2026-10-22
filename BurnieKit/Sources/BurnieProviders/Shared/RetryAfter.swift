import Foundation

/// A 429's `Retry-After` header: seconds or an HTTP date.
enum RetryAfter {
    /// A negative, infinite or NaN number of seconds reads as no `Retry-After` (B-24).
    static func date(from value: String?, now: Date) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        if let seconds = TimeInterval(value) {
            return seconds.isFinite && seconds >= 0 ? now.addingTimeInterval(seconds) : nil
        }
        return httpDate.date(from: value)
    }

    private static var httpDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }
}
