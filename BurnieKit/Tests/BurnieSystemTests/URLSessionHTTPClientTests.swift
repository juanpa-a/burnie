import Foundation
import os
import Testing
@testable import BurnieSystem

struct URLSessionHTTPClientTests {
    let client = URLSessionHTTPClient(allowedHosts: ["api.anthropic.com"], logger: Logger(subsystem: "dev.juanpa.burnie.tests", category: "http"))

    @Test func rejectsHostsOutsideTheAllowList() async {
        await #expect(throws: URLSessionHTTPClient.Failure.hostNotAllowed("example.com")) {
            try await client.get(URL(string: "https://example.com/api/oauth/usage")!, headers: ["Authorization": "Bearer secret"])
        }
    }

    @Test func rejectsPlainHTTPEvenForAllowedHosts() async {
        await #expect(throws: URLSessionHTTPClient.Failure.hostNotAllowed("api.anthropic.com")) {
            try await client.get(URL(string: "http://api.anthropic.com/api/oauth/usage")!, headers: [:])
        }
    }
}
