import BurnieDomain
import BurnieInterface
import Foundation

/// The money Cursor charged the plan on each day of the activity window, from the dashboard's usage events.
///
/// The endpoint is a paged POST. Pages are requested until a short one arrives; if the events that arrived
/// don't match the count Cursor reports (a page repeated or skipped while new events land), it throws
/// instead of returning a sum that might be off (B-47).
struct CursorSpendFetcher: Sendable {
    // A literal URL, so it always parses.
    static let url = URL(string: "https://cursor.com/api/dashboard/get-filtered-usage-events")!
    private static let pageSize = 1_000
    /// Ten pages a day, far more than a day of events; past it the sum isn't trusted.
    private static let maxPages = 10 * ActivityWindow.dayCount

    private struct Query: Encodable {
        let page: Int
        let pageSize: Int
        let startDate: String
        let endDate: String
    }

    let dashboard: CursorDashboardClient
    let clock: any Clock

    /// The cents of every day of the window, 0 for a day without events (B-47).
    func dailySpentCents() async throws(ProviderIssue) -> [LocalDay: Cents] {
        let calendar = Calendar.gregorian(in: clock.timeZone)
        let window = ActivityWindow.days(endingAt: LocalDay(clock.now, in: calendar))
        let events = try await events(from: window.lowerBound.start(in: calendar), to: clock.now)
        return try CursorSpendMapper.dailySpentCents(from: events, in: window, calendar: calendar)
    }

    private func events(from start: Date, to end: Date) async throws(ProviderIssue) -> [CursorUsageEventsDTO.Event] {
        var events: [CursorUsageEventsDTO.Event] = []
        for number in 1...Self.maxPages {
            let page = try await page(number, from: start, to: end)
            let pageEvents = page.usageEventsDisplay ?? []
            events += pageEvents
            // A short page is the last one.
            if pageEvents.count < Self.pageSize {
                guard Self.addsUp(events.count, to: page.totalUsageEventsCount) else {
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
    private static func addsUp(_ count: Int, to reported: CursorUsageEventsDTO.Number?) -> Bool {
        guard let reported else { return true }
        return Int(exactly: reported.value) == count
    }
}
