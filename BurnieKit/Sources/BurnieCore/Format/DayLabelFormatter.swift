import Foundation

/// Chart day names in the system locale.
public struct DayLabelFormatter: Sendable {
    private let calendar: Calendar
    private let locale: Locale

    public init(locale: Locale) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
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
}
