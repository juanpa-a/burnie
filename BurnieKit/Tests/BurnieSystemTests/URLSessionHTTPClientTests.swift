import Foundation
import os
import Testing
@testable import BurnieSystem
import BurnieCore

struct URLSessionHTTPClientTests {
    let client = URLSessionHTTPClient(allowedHosts: ["api.anthropic.com"], logger: Logger(subsystem: "dev.juanpa.burnie.tests", category: "http"))

    @Test func rejectsHostsOutsideTheAllowList() async {
        await #expect(throws: URLSessionHTTPClient.Failure.hostNotAllowed("example.com")) {
            try await client.send(HTTPRequest(.get, url: URL(string: "https://example.com/api/oauth/usage")!, headers: ["Authorization": "Bearer secret"]))
        }
    }

    @Test func rejectsPlainHTTPEvenForAllowedHosts() async {
        await #expect(throws: URLSessionHTTPClient.Failure.hostNotAllowed("api.anthropic.com")) {
            try await client.send(HTTPRequest(.get, url: URL(string: "http://api.anthropic.com/api/oauth/usage")!, headers: [:]))
        }
    }

    @Test func postsCarryTheirBody() {
        let body = Data(#"{"page":1}"#.utf8)
        let request = URLSessionHTTPClient.urlRequest(for: HTTPRequest(.post(body), url: URL(string: "https://cursor.com/api/x")!, headers: ["Origin": "https://cursor.com"]))
        #expect(request.httpMethod == "POST")
        #expect(request.httpBody == body)
        #expect(request.value(forHTTPHeaderField: "Origin") == "https://cursor.com")
    }

    @Test func getsHaveNoBody() {
        let request = URLSessionHTTPClient.urlRequest(for: HTTPRequest(.get, url: URL(string: "https://cursor.com/api/x")!, headers: [:]))
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }
}
