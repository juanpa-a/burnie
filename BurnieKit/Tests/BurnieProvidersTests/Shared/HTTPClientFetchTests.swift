import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

/// The HTTP rules every provider shares, with no rules of its own on top.
struct HTTPClientFetchTests {
    static let now = Date.iso("2026-10-10T20:00:00Z")
    static let url = URL(string: "https://example.com/usage")!

    func fetch(from http: FakeHTTPClient, classify: (HTTPResponse) -> ProviderIssue? = { _ in nil }) async throws(ProviderIssue) -> Data {
        try await http.fetch(HTTPRequest(.get, url: Self.url, headers: [:]), now: Self.now, classify: classify)
    }

    @Test("B-24 no response, because of no network or a timeout, reads as offline")
    func noResponseIsOffline() async {
        await #expect(throws: ProviderIssue.offline) { try await fetch(from: FakeHTTPClient(failingWith: .offline)) }
    }

    @Test("B-24 any other failure to get a response reads as unexpected, described for the logs")
    func otherFailuresAreUnexpected() async {
        await #expect(throws: ProviderIssue.unexpectedResponse("refused")) { try await fetch(from: FakeHTTPClient(failingWith: .other("refused"))) }
    }

    @Test("B-24 a 2xx answers its body")
    func successAnswersTheBody() async throws {
        #expect(try await fetch(from: FakeHTTPClient(status: 200, body: Data("ok".utf8))) == Data("ok".utf8))
    }

    @Test("B-24 a 429 is rate limited until its Retry-After, in seconds or as an HTTP date", arguments: [
        ("120", Date.iso("2026-10-10T20:02:00Z")),
        ("Sat, 10 Oct 2026 21:00:00 GMT", Date.iso("2026-10-10T21:00:00Z")),
        ("soon", nil),
        (nil, nil),
    ] as [(String?, Date?)])
    func rateLimitedUntilRetryAfter(retryAfter: String?, retryAt: Date?) async {
        let http = FakeHTTPClient(status: 429, headers: retryAfter.map { ["Retry-After": $0] } ?? [:])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: retryAt)) { try await fetch(from: http) }
    }

    @Test("B-24 a 5xx reads as offline", arguments: [500, 502, 503, 599])
    func serverErrorsAreOffline(status: Int) async {
        await #expect(throws: ProviderIssue.offline) { try await fetch(from: FakeHTTPClient(status: status)) }
    }

    @Test("B-24 any other non-2xx reads as unexpected", arguments: [302, 400, 404, 418])
    func otherStatusesAreUnexpected(status: Int) async {
        await #expect(throws: ProviderIssue.unexpectedResponse("HTTP \(status)")) { try await fetch(from: FakeHTTPClient(status: status)) }
    }

    @Test("B-24 429 and 5xx are classified before the provider's own rules")
    func sharedRulesComeBeforeTheProvidersOwn() async {
        let expired: (HTTPResponse) -> ProviderIssue? = { _ in .signInExpired }
        await #expect(throws: ProviderIssue.rateLimited(retryAt: nil)) { try await fetch(from: FakeHTTPClient(status: 429), classify: expired) }
        await #expect(throws: ProviderIssue.offline) { try await fetch(from: FakeHTTPClient(status: 503), classify: expired) }
    }
}
