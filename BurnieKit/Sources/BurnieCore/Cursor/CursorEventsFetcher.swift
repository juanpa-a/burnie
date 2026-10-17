import Foundation

/// Tokens per day from Cursor's events CSV, requested only for the activity window.
/// Without a range, the endpoint stops at 7000 rows and takes longer than the timeout.
struct CursorEventsFetcher {
    private let dashboard: CursorDashboardClient
    private let clock: Clock

    init(dashboard: CursorDashboardClient, clock: Clock) {
        self.dashboard = dashboard
        self.clock = clock
    }

    func dailyTokens() async throws(ProviderIssue) -> [LocalDay: Int] {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let window = ActivityWindow.days(endingAt: LocalDay(clock.now, in: calendar))
        let url = Self.url(from: window.lowerBound.start(in: calendar), to: clock.now)
        let body = try await dashboard.get(url, accept: "text/csv")
        return try CursorUsageEvents.dailyTokens(csv: String(decoding: body, as: UTF8.self), in: window, calendar: calendar)
    }

    static func url(from start: Date, to end: Date) -> URL {
        // A literal URL, so it always parses.
        var components = URLComponents(string: "https://cursor.com/api/dashboard/export-usage-events-csv")!
        components.queryItems = [
            URLQueryItem(name: "strategy", value: "tokens"),
            URLQueryItem(name: "startDate", value: start.unixMillisecondsString),
            URLQueryItem(name: "endDate", value: end.unixMillisecondsString),
        ]
        // A literal https URL with plain query items always forms a URL.
        return components.url!
    }
}
