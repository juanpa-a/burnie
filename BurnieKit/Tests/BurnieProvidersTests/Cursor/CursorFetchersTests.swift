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

    @Test("B-26 a redirect or 401 is sign-in expired", arguments: [401, 302])
    func loginResponsesAreSignInExpired(status: Int) async {
        http.respond(status: status)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test("B-26 a 403 is Cursor refusing Burnie, so it reads as unexpected")
    func forbiddenIsUnexpected() async {
        http.respond(status: 403)
        await #expect(throws: ProviderIssue.unexpectedResponse("HTTP 403")) { try await limits() }
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

    @Test("B-47 the events CSV is a GET for the activity window alone, without an Origin")
    func eventsAskOnlyForTheActivityWindow() async throws {
        http.respond(status: 200, body: Fixture.data("cursor-events.csv"), headers: ["Content-Type": "text/csv; charset=utf-8"])
        let totals = try await CursorEventsFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now)).dailyTokens()

        #expect(totals[.day("2026-10-10")] == Tokens(2_662_000))
        let windowStart = Int64(Date.iso("2026-10-03T06:00:00Z").timeIntervalSince1970 * 1_000)
        let windowEnd = Int64(Self.now.timeIntervalSince1970 * 1_000)
        #expect(http.requests.first?.url.absoluteString == "https://cursor.com/api/dashboard/export-usage-events-csv?strategy=tokens&startDate=\(windowStart)&endDate=\(windowEnd)")
        #expect(http.requests.first?.headers == [
            "Cookie": try CursorAccessToken(jwt: CursorAccessTokenTests.jwt).sessionCookie,
            "Accept": "text/csv",
            "User-Agent": "Burnie/0.1.0",
        ])
    }
}
