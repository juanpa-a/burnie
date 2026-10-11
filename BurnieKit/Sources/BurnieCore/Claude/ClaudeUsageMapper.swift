import Foundation

/// From `ClaudeUsageDTO` to the Session and Weekly meters. Prefers `limits[]` and falls back to the flat windows.
enum ClaudeUsageMapper {
    private struct Window {
        let percent: Double
        let resetsAt: Date?
    }

    static func meters(from usage: ClaudeUsageDTO) throws(ProviderIssue) -> [Meter] {
        let session = window(kind: "session", in: usage) ?? window(usage.fiveHour)
        let weekly = window(kind: "weekly_all", in: usage) ?? window(usage.sevenDay)
        guard session != nil || weekly != nil else { throw .unexpectedResponse("Claude usage without windows") }
        return [session.map(sessionMeter), weekly.map(weeklyMeter)].compactMap { $0 }
    }

    private static func sessionMeter(_ window: Window) -> Meter {
        .percent(.session, used: window.percent, caption: window.resetsAt.map(MeterCaption.resetsIn) ?? .noActiveSession)
    }

    /// Without a reset date, the weekly window hasn't started yet.
    private static func weeklyMeter(_ window: Window) -> Meter {
        .percent(.weekly, used: window.percent, caption: window.resetsAt.map(MeterCaption.resetsAt) ?? .noActiveSession)
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
