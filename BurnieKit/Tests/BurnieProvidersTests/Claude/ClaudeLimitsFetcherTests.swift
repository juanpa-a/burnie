import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct ClaudeLimitsFetcherTests {
    static let paths = ClaudePaths(home: URL(filePath: "/home"))
    static let beforeExpiry = Date.iso("2026-10-11T02:00:00Z") // the fixture's token expires at 05:00 UTC
    /// A file in each Claude Code folder, so the folder exists: `~/.claude`'s, and the XDG one.
    static let settingsFile = paths.claudeCodeFolders[1].appending(path: "settings.json")
    static let xdgSettingsFile = paths.claudeCodeFolders[0].appending(path: "settings.json")

    var secrets = FakeSecretReader(items: [ClaudeCredentialsReader.keychainService: Fixture.data("claude-credentials.json")])
    let files = InMemoryFiles()
    let http = FakeHTTPClient(status: 200, body: Fixture.data("claude-usage-both.json"))
    var now = beforeExpiry

    /// Claude Code is installed.
    init() {
        files.write(Data("{}".utf8), to: Self.settingsFile, modified: Self.beforeExpiry)
    }

    func limits() async throws(ProviderIssue) -> LimitsPart {
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

    @Test("B-28 Claude's plan comes from the profile, asked with the OAuth token")
    func readsMetersWithTheOAuthTokenAndThePlanFromTheProfile() async throws {
        http.respond(to: ClaudeProfilePlan.url, body: Fixture.data("claude-profile.json"))
        let reading = try await limits()
        #expect(reading.plan == PlanName(rawValue: "MAX"))
        #expect(reading.meters.all == ClaudeUsageMapperTests.fixtureMeters)
        #expect(http.requests == [
            HTTPRequest(.get, url: ClaudeLimitsFetcher.usageURL, headers: Self.headers),
            HTTPRequest(.get, url: ClaudeProfilePlan.url, headers: Self.headers),
        ])
    }

    @Test("B-28 without the profile, Claude's plan comes from the credentials")
    func fallsBackToTheCredentialsPlanWhenTheProfileFails() async throws {
        http.respond(to: ClaudeProfilePlan.url, status: 503)
        #expect(try await limits().plan?.rawValue == "PRO")
    }

    @Test("B-27 without a Keychain item, Claude reads the credentials file")
    mutating func fallsBackToTheCredentialsFile() async throws {
        secrets.items = [:]
        files.write(Fixture.data("claude-credentials.json"), to: Self.paths.credentialsFile, modified: now)
        #expect(try await limits().plan?.rawValue == "PRO")
    }

    @Test("B-27 the Keychain item comes before the credentials file")
    func readsTheKeychainBeforeTheCredentialsFile() async throws {
        let fileCredentials = #"{"claudeAiOauth":{"accessToken":"from-the-file","subscriptionType":"team"}}"#
        files.write(Data(fileCredentials.utf8), to: Self.paths.credentialsFile, modified: now)
        #expect(try await limits().plan?.rawValue == "PRO")
        #expect(http.requests.first?.headers["Authorization"] == Self.headers["Authorization"])
    }

    @Test("B-27 without the Keychain item or the credentials file, Claude is not found")
    mutating func withoutCredentialsIsNotFound() async {
        secrets.items = [:]
        await #expect(throws: ProviderIssue.notFound) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-27 without a Claude Code folder, Claude is not found and its Keychain item isn't read")
    func withoutClaudeCodeTheKeychainIsNotRead() async {
        files.remove(Self.settingsFile)
        // The Keychain still holds the item: reading it would have found the credentials.
        await #expect(throws: ProviderIssue.notFound) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-27 the XDG folder alone is enough for Claude Code to be installed")
    func theXDGFolderIsEnough() async throws {
        files.remove(Self.settingsFile)
        files.write(Data("{}".utf8), to: Self.xdgSettingsFile, modified: now)
        #expect(try await limits().meters.all == ClaudeUsageMapperTests.fixtureMeters)
    }

    @Test("B-25 an expired token is sign-in expired before any request")
    mutating func expiredTokenNeverReachesTheNetwork() async {
        now = .iso("2026-10-11T06:00:00Z")
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
        #expect(http.requests.isEmpty)
    }

    @Test("B-25 a 401 is sign-in expired")
    func unauthorizedIsSignInExpired() async {
        http.respond(status: 401)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test("B-25 a 403 mentioning user:profile is missing scope")
    func forbiddenForScopeIsMissingScope() async {
        http.respond(status: 403, body: Fixture.data("claude-403-scope.json"))
        await #expect(throws: ProviderIssue.specific(.missingScope)) { try await limits() }
    }

    @Test("B-25 a 403 that doesn't mention user:profile is sign-in expired", arguments: [
        #"{"type":"error","error":{"type":"permission_error","message":"OAuth token has been revoked"}}"#,
        "",
    ])
    func otherForbiddenIsSignInExpired(body: String) async {
        http.respond(status: 403, body: Data(body.utf8))
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
    }

    @Test("B-61 an expired sign-in never makes Burnie refresh the token: the usage request is the only one")
    func expiredSignInNeverRefreshesTheToken() async {
        http.respond(status: 401)
        await #expect(throws: ProviderIssue.signInExpired) { try await limits() }
        #expect(http.requests.map(\.url) == [ClaudeLimitsFetcher.usageURL])
    }

    @Test("B-24 a 429 is rate limited with Retry-After in seconds or as an HTTP date")
    func rateLimitedHonorsRetryAfter() async {
        http.respond(status: 429, headers: ["Retry-After": "120"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: Self.beforeExpiry.addingTimeInterval(120))) { try await limits() }
        http.respond(status: 429, headers: ["Retry-After": "Sun, 11 Oct 2026 03:00:00 GMT"])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: .iso("2026-10-11T03:00:00Z"))) { try await limits() }
        http.respond(status: 429)
        await #expect(throws: ProviderIssue.rateLimited(retryAt: nil)) { try await limits() }
    }

    @Test("B-24 server errors and a missing network are offline")
    func serverErrorsAndMissingNetworkAreOffline() async {
        http.respond(status: 503)
        await #expect(throws: ProviderIssue.offline) { try await limits() }

        let offline = ClaudeLimitsFetcher(
            credentials: ClaudeCredentialsReader(secrets: secrets, files: files, paths: Self.paths, account: "dev"),
            http: FakeHTTPClient(failingWith: .offline),
            clock: FixedClock(now: now),
            userAgent: "Burnie/0.1.0"
        )
        await #expect(throws: ProviderIssue.offline) { try await offline.limits() }
    }

    @Test("B-49 usage without windows, or not JSON, is unexpected")
    func okWithoutWindowsIsUnexpected() async {
        http.respond(status: 200, body: Data(#"{"extra_usage":{"is_enabled":false}}"#.utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Claude usage without windows")) { try await limits() }
        http.respond(status: 200, body: Data("<html>".utf8))
        await #expect(throws: ProviderIssue.unexpectedResponse("Claude usage is not JSON")) { try await limits() }
    }
}
