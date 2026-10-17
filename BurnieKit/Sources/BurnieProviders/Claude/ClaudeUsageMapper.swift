import BurnieDomain
import Foundation

/// From `ClaudeUsageDTO` to the session and weekly meters. Prefers `limits[]` and falls back to the flat windows (B-49).
enum ClaudeUsageMapper {
    private struct Window {
        let percent: Double
        let resetsAt: Date?

        /// The window ends at its reset; without one it hasn't started.
        func period(lasting length: TimeInterval) -> DateInterval? {
            resetsAt.map { DateInterval(start: $0.addingTimeInterval(-length), duration: length) }
        }
    }

    private static let sessionLength: TimeInterval = 5 * 3_600
    private static let weeklyLength: TimeInterval = 7 * 86_400

    /// The session meter is primary when there is one.
    static func meters(from usage: ClaudeUsageDTO) throws(ProviderIssue) -> MeterSet {
        let session = window(kind: "session", in: usage) ?? window(usage.fiveHour)
        let weekly = window(kind: "weekly_all", in: usage) ?? window(usage.sevenDay)
        guard let meters = MeterSet([session.map(sessionMeter), weekly.map(weeklyMeter)].compactMap { $0 }) else {
            throw .unexpectedResponse("Claude usage without windows")
        }
        return meters
    }

    private static func sessionMeter(_ window: Window) -> Meter {
        .percent(
            .session,
            used: window.percent,
            caption: window.resetsAt.map(MeterCaption.resetsIn) ?? .noActiveSession,
            period: window.period(lasting: sessionLength)
        )
    }

    /// Without a reset date, the weekly window hasn't started yet.
    private static func weeklyMeter(_ window: Window) -> Meter {
        .percent(
            .weekly,
            used: window.percent,
            caption: window.resetsAt.map(MeterCaption.resetsAt) ?? .noActiveSession,
            period: window.period(lasting: weeklyLength)
        )
    }

    private static func window(kind: String, in usage: ClaudeUsageDTO) -> Window? {
        guard let limit = usage.limits?.first(where: { $0.kind == kind }), let percent = limit.percent else { return nil }
        return Window(percent: percent, resetsAt: limit.resetsAt.flatMap(ISO8601DateParser.date(from:)))
    }

    private static func window(_ window: ClaudeUsageDTO.Window?) -> Window? {
        guard let window, let percent = window.utilization else { return nil }
        return Window(percent: percent, resetsAt: window.resetsAt.flatMap(ISO8601DateParser.date(from:)))
    }
}
