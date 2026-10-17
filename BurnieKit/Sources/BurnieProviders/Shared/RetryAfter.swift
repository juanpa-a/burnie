import Foundation

/// A 429's `Retry-After` header: seconds or an HTTP date.
enum RetryAfter {
    static func date(from value: String?, now: Date) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        if let seconds = TimeInterval(value) {
            return now.addingTimeInterval(seconds)
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
