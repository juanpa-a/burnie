import BurnieDomain
import Foundation

/// Chart day names in the system locale.
public struct DayLabelFormatter: Sendable {
    private let calendar: Calendar
    private let locale: Locale

    public init(locale: Locale) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        // A day is drawn from its midnight in GMT, so no time zone moves it to another date.
        calendar.timeZone = .gmt
        self.calendar = calendar
        self.locale = locale
    }

    /// The letter under each column, always uppercase as in the design: "S", "M"… (Spanish symbols come in lowercase).
    public func letter(for day: LocalDay) -> String {
        String(calendar.veryShortWeekdaySymbols[day.weekday - 1].prefix(1)).uppercased(with: locale)
    }

    /// For VoiceOver: "Sat", "Sun"…
    public func shortName(for day: LocalDay) -> String {
        calendar.shortWeekdaySymbols[day.weekday - 1]
    }

    /// Over the week chart's tooltip: "Sat 10", "Mon 19"… (B-77)
    public func shortDate(for day: LocalDay) -> String {
        "\(shortName(for: day)) \(day.dayOfMonth.formatted(.number.locale(locale)))"
    }

    /// The day a cycle total counts from: "Oct 3", "3 oct"… (B-80)
    public func monthDay(for day: LocalDay) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        return day.start(in: calendar).formatted(style.month(.abbreviated).day())
    }
}
