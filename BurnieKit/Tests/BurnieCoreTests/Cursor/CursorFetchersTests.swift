import Foundation
import Testing
@testable import BurnieCore

struct CursorFetchersTests {
    static let now = Date.iso("2026-10-11T02:00:00Z") // 20:00 on the 10th in Mexico City

    var database = FakeKeyValueDatabase(rows: [CursorCredentialsReader.tokenKey: CursorAccessTokenTests.jwt])
    let http = FakeHTTPClient(status: 200, body: Fixture.data("cursor-summary-pro.json"), headers: ["Content-Type": "application/json; charset=utf-8"])

    var dashboard: CursorDashboardClient {
        CursorDashboardClient(
            credentials: CursorCredentialsReader(database: database, paths: CursorPaths(home: URL(filePath: "/home"))),
            http: http,
            clock: FixedClock(now: Self.now),
            userAgent: "Burnie/0.1.0"
        )
    }

    func limits() async throws(ProviderIssue) -> LimitsReading {
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

    @Test mutating func withoutTokenIsNotFoundAndNeverCallsTheNetwork() async {
        database.rows = [:]
        await #expect(throws: ProviderIssue.notFound) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test(arguments: [401, 403, 302])
    func loginResponsesAreSignInExpired(status: Int) async {
        http.respond(status: status)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test func loginPageInsteadOfJSONIsSignInExpired() async {
        http.respond(status: 200, body: Data("<!doctype html>".utf8), headers: ["Content-Type": "text/html; charset=utf-8"])
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test func sharedHTTPRulesApply() async {
        http.respond(status: 429, headers: ["Retry-After": "60"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: Self.now.addingTimeInterval(60))) { try await limits() }
        http.respond(status: 502)
        await #expect(throws: ProviderIssue.offline) { try await limits() }
        http.respond(status: 200, body: Data("not json".utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Cursor summary is not JSON")) { try await limits() }
    }

    @Test func eventsAskOnlyForTheActivityWindow() async throws {
        http.respond(status: 200, body: Fixture.data("cursor-events.csv"), headers: ["Content-Type": "text/csv; charset=utf-8"])
        let totals = try await CursorEventsFetcher(dashboard: dashboard, clock: FixedClock(now: Self.now)).dailyTokens()

        #expect(totals[.day("2026-10-10")] == 2_662_000)
        let windowStart = Int64(Date.iso("2026-10-03T06:00:00Z").timeIntervalSince1970 * 1_000)
        let windowEnd = Int64(Self.now.timeIntervalSince1970 * 1_000)
        #expect(http.requests.first?.url.absoluteString == "https://cursor.com/api/dashboard/export-usage-events-csv?strategy=tokens&startDate=\(windowStart)&endDate=\(windowEnd)")
        #expect(http.requests.first?.headers["Accept"] == "text/csv")
    }
}
