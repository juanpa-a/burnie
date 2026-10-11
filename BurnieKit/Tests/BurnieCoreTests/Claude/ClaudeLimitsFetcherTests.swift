import Foundation
import Testing
@testable import BurnieCore

struct ClaudeLimitsFetcherTests {
    static let paths = ClaudePaths(home: URL(filePath: "/home"))
    static let beforeExpiry = Date.iso("2026-10-11T02:00:00Z") // the fixture's token expires at 05:00 UTC

    var secrets = FakeSecretReader(items: [ClaudeCredentialsReader.keychainService: Fixture.data("claude-credentials.json")])
    let files = InMemoryFiles()
    let http = FakeHTTPClient(status: 200, body: Fixture.data("claude-usage-both.json"))
    var now = beforeExpiry

    func limits() async throws(ProviderIssue) -> LimitsReading {
        try await ClaudeLimitsFetcher(
            credentials: ClaudeCredentialsReader(secrets: secrets, files: files, paths: Self.paths, account: "dev"),
            http: http,
            clock: FixedClock(now: now),
            userAgent: "Burnie/0.1.0"
        ).limits()
    }

    static let headers = [
        "Authorization": "Bearer sk-ant-oat01-SCRUBBED",
        "anthropic-beta": "oauth-2025-04-20",
        "Accept": "application/json",
        "User-Agent": "Burnie/0.1.0",
    ]

    @Test func readsMetersWithTheOAuthTokenAndThePlanFromTheProfile() async throws {
        http.respond(to: ClaudeProfilePlan.url, body: Fixture.data("claude-profile.json"))
        let reading = try await limits()
        #expect(reading == LimitsReading(plan: "MAX", meters: ClaudeUsageMapperTests.fixtureMeters))
        #expect(http.requests == [
            .init(url: ClaudeLimitsFetcher.usageURL, headers: Self.headers),
            .init(url: ClaudeProfilePlan.url, headers: Self.headers),
        ])
    }

    @Test func fallsBackToTheCredentialsPlanWhenTheProfileFails() async throws {
        http.respond(to: ClaudeProfilePlan.url, status: 503)
        #expect(try await limits().plan == "PRO")
    }

    @Test mutating func fallsBackToTheCredentialsFile() async throws {
        secrets.items = [:]
        files.write(Fixture.data("claude-credentials.json"), to: Self.paths.credentialsFile, modified: now)
        #expect(try await limits().plan == "PRO")
    }

    @Test mutating func withoutCredentialsIsNotFound() async {
        secrets.items = [:]
        await #expect(throws: ProviderIssue.notFound) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test mutating func expiredTokenNeverReachesTheNetwork() async {
        now = .iso("2026-10-11T06:00:00Z")
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test func unauthorizedIsSignInExpired() async {
        http.respond(status: 401)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test func forbiddenForScopeIsMissingScope() async {
        http.respond(status: 403, body: Fixture.data("claude-403-scope.json"))
        await #expect(throws: ProviderIssue.missingScope) { try await limits() }
    }

    @Test func rateLimitedHonorsRetryAfter() async {
        http.respond(status: 429, headers: ["Retry-After": "120"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: Self.beforeExpiry.addingTimeInterval(120))) { try await limits() }
        http.respond(status: 429, headers: ["Retry-After": "Sun, 11 Oct 2026 03:00:00 GMT"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: .iso("2026-10-11T03:00:00Z"))) { try await limits() }
        http.respond(status: 429)
        await #expect(throws: ProviderIssue.rateLimited(retryAt: nil)) { try await limits() }
    }

    @Test func serverErrorsAndMissingNetworkAreOffline() async {
        http.respond(status: 503)
        await #expect(throws: ProviderIssue.offline) { try await limits() }

        let offline = ClaudeLimitsFetcher(
            credentials: ClaudeCredentialsReader(secrets: secrets, files: files, paths: Self.paths, account: "dev"),
            http: FakeHTTPClient(failingWith: URLError(.notConnectedToInternet)),
            clock: FixedClock(now: now),
            userAgent: "Burnie/0.1.0"
        )
        await #expect(throws: ProviderIssue.offline) { try await offline.limits() }
    }

    @Test func okWithoutWindowsIsUnexpected() async {
        http.respond(status: 200, body: Data(#"{"extra_usage":{"is_enabled":false}}"#.utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Claude usage without windows")) { try await limits() }
        http.respond(status: 200, body: Data("<html>".utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Claude usage is not JSON")) { try await limits() }
    }
}

struct ClaudePathsTests {
    let paths = ClaudePaths(home: URL(filePath: "/Users/dev"))

    @Test func showsLogRootsRelativeToHome() {
        #expect(paths.logRoots.map { paths.displayName(ofLogRoot: $0) } == ["~/.config/claude", "~/.claude"])
    }
}

struct ClaudeProfilePlanTests {
    let now = Date.iso("2026-10-11T02:00:00Z")
    let http = FakeHTTPClient(status: 200, body: Fixture.data("claude-profile.json"))

    @Test func asksTheProfileAtMostOncePerHour() async {
        let plan = ClaudeProfilePlan(http: http)
        #expect(await plan.chip(headers: [:], now: now) == "MAX")
        #expect(await plan.chip(headers: [:], now: now.addingTimeInterval(59 * 60)) == "MAX")
        #expect(http.requests.count == 1)
        _ = await plan.chip(headers: [:], now: now.addingTimeInterval(61 * 60))
        #expect(http.requests.count == 2)
    }

    @Test func keepsTheLastPlanWhenARefreshFails() async {
        let plan = ClaudeProfilePlan(http: http)
        _ = await plan.chip(headers: [:], now: now)
        http.respond(status: 429)
        #expect(await plan.chip(headers: [:], now: now.addingTimeInterval(2 * 60 * 60)) == "MAX")
    }

    @Test func withoutAnAnswerThereIsNoPlan() async {
        http.respond(status: 401)
        #expect(await ClaudeProfilePlan(http: http).chip(headers: [:], now: now) == nil)
    }
}
