import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorFetchersTests {
    static let now = Date.iso("2026-10-11T02:00:00Z") // 20:00 on the 10th in Mexico City

    var database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
    /// What the dashboard's clock reads, so a test can expire the session; the fetchers' own clocks stay at `Self.now`.
    var now = Self.now
    let http = FakeHTTPClient(status: 200, body: Fixture.data("cursor-summary-pro.json"), headers: ["Content-Type": "application/json; charset=utf-8"])

    var dashboard: CursorDashboardClient {
        CursorDashboardClient(
            credentials: CursorCredentialsReader(database: database, paths: CursorPaths(home: URL(filePath: "/home"))),
            http: http,
            clock: FixedClock(now: now),
            userAgent: "Burnie/0.1.0"
        )
    }

    var activity: CursorActivity {
        CursorActivity(
            tokens: CursorEventsFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now)),
            spend: CursorSpendFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now))
        )
    }

    func limits() async throws(ProviderIssue) -> LimitsPart {
        try await CursorSummaryFetcher(dashboard: dashboard).limits()
    }

    @Test func summarySendsTheSessionCookie() async throws {
        #expect(try await limits().meters == CursorUsageMapperTests.pools)
        let request = try #require(http.requests.first)
        #expect(request.url == CursorSummaryFetcher.url)
        #expect(request.headers == [
            "Cookie": try CursorAccessToken(jwt: CursorAccessTokenTests.jwt).sessionCookie,
            "Accept": "application/json",
            "User-Agent": "Burnie/0.1.0",
        ])
    }

    @Test("B-26 without a session Cursor is not found and never reaches the network")
    mutating func withoutTokenIsNotFoundAndNeverCallsTheNetwork() async {
        database.rows = [:]
        await #expect(throws: ProviderIssue.notFound) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-26 a malformed session is sign-in expired and never reaches the network")
    mutating func malformedSessionNeverReachesTheNetwork() async {
        database.rows = [CursorCredentialsReader.tokenKey: "not-a-jwt"]
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-26 an expired session is sign-in expired and never reaches the network")
    mutating func expiredSessionNeverReachesTheNetwork() async {
        now = .iso("2026-11-27T00:00:00Z") // the fixture's token expired on November 18
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-26 a redirect, 401 or 403 is sign-in expired", arguments: [401, 403, 302])
    func loginResponsesAreSignInExpired(status: Int) async {
        http.respond(status: status)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test("B-26 HTML instead of data is sign-in expired")
    func loginPageInsteadOfJSONIsSignInExpired() async {
        http.respond(status: 200, body: Data("<!doctype html>".utf8), mimeType: "text/html")
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test("B-24 Cursor follows the shared HTTP rules")
    func sharedHTTPRulesApply() async {
        http.respond(status: 429, headers: ["Retry-After": "60"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: Self.now.addingTimeInterval(60))) { try await limits() }
        http.respond(status: 502)
        await #expect(throws: ProviderIssue.offline) { try await limits() }
        http.respond(status: 200, body: Data("not json".utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary is not JSON")) { try await limits() }
    }

    @Test("B-47 the events CSV is requested only for the activity window")
    func eventsAskOnlyForTheActivityWindow() async throws {
        http.respond(status: 200, body: Fixture.data("cursor-events.csv"), headers: ["Content-Type": "text/csv; charset=utf-8"])
        let totals = try await CursorEventsFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now)).dailyTokens()

        #expect(totals[.day("2026-10-10")] == Tokens(2_662_000))
        let windowStart = Int64(Date.iso("2026-10-03T06:00:00Z").timeIntervalSince1970 * 1_000)
        let windowEnd = Int64(Self.now.timeIntervalSince1970 * 1_000)
        #expect(http.requests.first?.url.absoluteString == "https://cursor.com/api/dashboard/export-usage-events-csv?strategy=tokens&startDate=\(windowStart)&endDate=\(windowEnd)")
        #expect(http.requests.first?.headers["Accept"] == "text/csv")
    }

    func spentToday() async throws(ProviderIssue) -> [LocalDay: Cents] {
        try await CursorSpendFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now)).dailySpentCents()
    }

    @Test("B-47 spend comes from the usage events of today, asked like the dashboard")
    func spendPostsTodaysRangeLikeTheDashboard() async throws {
        http.respond(to: CursorSpendFetcher.url, body: Fixture.data("cursor-usage-events.json"))
        #expect(try await spentToday() == [.day("2026-10-10"): Cents(117)])

        let request = try #require(http.requests.first)
        guard case .post(let body) = request.method else { Issue.record("Expected a POST"); return }
        let query = try JSONSerialization.jsonObject(with: body) as? NSDictionary
        #expect(query == ["page": 1, "pageSize": 1_000, "startDate": "1791612000000", "endDate": "1791684000000"])
        #expect(request.headers["Origin"] == "https://cursor.com")
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.headers["Cookie"] == (try CursorAccessToken(jwt: CursorAccessTokenTests.jwt).sessionCookie))
    }

    @Test("B-47 an empty usage events answer means nothing was spent today")
    func anEmptyAnswerMeansNothingSpentToday() async throws {
        http.respond(to: CursorSpendFetcher.url, body: Data("{}".utf8))
        #expect(try await spentToday() == [.day("2026-10-10"): Cents(0)])
    }

    @Test("B-47 spend reads pages until a short one")
    func spendReadsEveryPage() async throws {
        http.respond(to: CursorSpendFetcher.url, withEach: [Self.page(events: 1_000, reported: 1_001), Self.page(events: 1, reported: 1_001)])
        #expect(try await spentToday() == [.day("2026-10-10"): Cents(1_001)])
        #expect(http.requests.count == 2)
    }

    @Test("B-47 pages that don't add up to the reported count make the spend unknown")
    func pagesThatDontAddUpAreNotSummed() async {
        http.respond(to: CursorSpendFetcher.url, withEach: [Self.page(events: 1_000, reported: 1_002), Self.page(events: 1, reported: 1_002)])
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor usage events don't add up")) { try await spentToday() }
    }

    @Test("B-47 Cursor's activity carries tokens and today's spend")
    func activityCarriesTodaysSpend() async throws {
        http.respond(status: 200, body: Fixture.data("cursor-events.csv"), headers: ["Content-Type": "text/csv; charset=utf-8"])
        http.respond(to: CursorSpendFetcher.url, body: Fixture.data("cursor-usage-events.json"))
        let reading = try await activity.activity()
        #expect(reading.tokens[.day("2026-10-10")] == Tokens(2_662_000))
        #expect(reading.spent == [.day("2026-10-10"): Cents(117)])
    }

    @Test("B-47 a failed spend request, a 429 included, keeps the tokens and leaves spend unknown", arguments: [403, 429, 503])
    func failedSpendRequestKeepsTheTokens(status: Int) async throws {
        http.respond(to: CursorSpendFetcher.url, status: status, headers: ["Retry-After": "60"])
        let reading = try await activityReading()
        #expect(reading.tokens[.day("2026-10-10")] == Tokens(2_662_000))
        #expect(reading.spent.isEmpty)
    }

    @Test("B-47 spend that can't be added up exactly keeps the tokens and leaves spend unknown", arguments: [
        [page(events: 1_000, reported: 1_002), page(events: 1, reported: 1_002)],
        [Data(#"{"totalUsageEventsCount":1,"usageEventsDisplay":[{"timestamp":"1791648000000"}]}"#.utf8)],
    ])
    func spendThatDoesntAddUpKeepsTheTokens(pages: [Data]) async throws {
        http.respond(to: CursorSpendFetcher.url, withEach: pages)
        let reading = try await activityReading()
        #expect(reading.tokens[.day("2026-10-10")] == Tokens(2_662_000))
        #expect(reading.spent.isEmpty)
    }

    /// Cursor's activity, with the events CSV answering every request the test didn't route elsewhere.
    func activityReading() async throws(ProviderIssue) -> ActivityPart {
        http.respond(status: 200, body: Fixture.data("cursor-events.csv"), headers: ["Content-Type": "text/csv; charset=utf-8"])
        return try await activity.activity()
    }

    /// A page of `events` one-cent charges at 10:00 on the 10th in Mexico City.
    static func page(events: Int, reported: Int) -> Data {
        let event = #"{"timestamp":"1791648000000","chargedCents":1}"#
        let display = Array(repeating: event, count: events).joined(separator: ",")
        return Data(#"{"totalUsageEventsCount":\#(reported),"usageEventsDisplay":[\#(display)]}"#.utf8)
    }
}
