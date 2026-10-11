import Foundation

/// The text under each meter: when it resets, or what being empty means.
public struct MeterCaptionFormatter: Sendable {
    public let locale: Locale
    public let timeZone: TimeZone

    public init(locale: Locale, timeZone: TimeZone) {
        self.locale = locale
        self.timeZone = timeZone
    }

    public func string(for caption: MeterCaption, now: Date) -> String {
        switch caption {
        case .resetsIn(let date): "Resets in " + countdown(from: now, to: date)
        case .resetsAt(let date): "Resets \(dateStyle.weekday(.abbreviated).format(date)), \(dateStyle.hour().minute().format(date))"
        case .cycleEnds(let date): cycleEnd(date, now: now)
        case .noActiveSession: "No active session"
        case .onDemandIdle: "Kicks in after included usage runs out"
        }
    }

    /// "2h 14m", "45m" or "<1m"; minutes are truncated.
    private func countdown(from now: Date, to date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(now) / 60)
        guard minutes >= 1 else { return "<1m" }
        guard minutes >= 60 else { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    /// "Resets Nov 1 · 21 days left", "Resets Nov 1 · 1 day left" or "Resets today".
    private func cycleEnd(_ date: Date, now: Date) -> String {
        let daysLeft = LocalDay(now, in: calendar).distance(to: LocalDay(date, in: calendar))
        guard daysLeft > 0 else { return "Resets today" }
        let unit = daysLeft == 1 ? "day" : "days"
        return "Resets \(dateStyle.month(.abbreviated).day().format(date)) · \(daysLeft) \(unit) left"
    }

    private var calendar: Calendar { .gregorian(in: timeZone) }

    private var dateStyle: Date.FormatStyle {
        Date.FormatStyle(locale: locale, calendar: calendar, timeZone: timeZone)
    }
}
