import Foundation

/// The money Cursor charged the plan today, from the dashboard's usage events.
///
/// The endpoint is a paged POST. Pages are requested until a short one arrives; if the events that arrived
/// don't match the count Cursor reports (a page repeated or skipped while new events land), it throws
/// instead of returning a sum that might be off.
struct CursorSpendFetcher {
    static let url = URL(string: "https://cursor.com/api/dashboard/get-filtered-usage-events")!
    static let pageSize = 1_000
    /// Far more than a day of events; past it the sum isn't trusted.
    static let maxPages = 10

    private struct Query: Encodable {
        let page: Int
        let pageSize: Int
        let startDate: String
        let endDate: String
    }

    private let dashboard: CursorDashboardClient
    private let clock: Clock

    init(dashboard: CursorDashboardClient, clock: Clock) {
        self.dashboard = dashboard
        self.clock = clock
    }

    /// Today's cents, keyed by today's local day.
    func dailySpentCents() async throws(ProviderIssue) -> [LocalDay: Int] {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let today = LocalDay(clock.now, in: calendar)
        let events = try await events(from: today.start(in: calendar), to: clock.now)
        return try CursorSpendMapper.dailySpentCents(from: events, in: today...today, calendar: calendar)
    }

    private func events(from start: Date, to end: Date) async throws(ProviderIssue) -> [CursorUsageEventsDTO.Event] {
        var events: [CursorUsageEventsDTO.Event] = []
        for number in 1...Self.maxPages {
            let page = try await page(number, from: start, to: end)
            let pageEvents = page.usageEventsDisplay ?? []
            events += pageEvents
            guard pageEvents.count == Self.pageSize else {
                guard Self.matches(events.count, reported: page.totalUsageEventsCount) else {
                    throw .unexpectedResponse("Cursor usage events don't add up")
                }
                return events
            }
        }
        throw .unexpectedResponse("Cursor usage events past \(Self.maxPages) pages")
    }

    private func page(_ number: Int, from start: Date, to end: Date) async throws(ProviderIssue) -> CursorUsageEventsDTO {
        let query = Query(page: number, pageSize: Self.pageSize, startDate: start.unixMillisecondsString, endDate: end.unixMillisecondsString)
        // Four plain fields always encode.
        let body = try await dashboard.post(Self.url, json: try! JSONEncoder().encode(query))
        guard let page = try? JSONDecoder().decode(CursorUsageEventsDTO.self, from: body) else {
            throw .unexpectedResponse("Cursor usage events are not JSON")
        }
        return page
    }

    /// Without a reported count there's nothing to check against.
    private static func matches(_ count: Int, reported: CursorUsageEventsDTO.Number?) -> Bool {
        guard let reported else { return true }
        return Int(exactly: reported.value) == count
    }
}
