import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInfra

struct URLSessionHTTPClientTests {
    let client = URLSessionHTTPClient(allowedHosts: ["api.anthropic.com"], log: RecordingDiagnosticsLog())

    @Test("B-60 a host outside the allowed ones is refused before any header is sent")
    func rejectsHostsOutsideTheAllowList() async {
        await #expect(throws: HTTPFailure.other("Host not allowed")) {
            try await client.send(HTTPRequest(.get, url: URL(string: "https://example.com/api/oauth/usage")!, headers: ["Authorization": "Bearer secret"]))
        }
    }

    @Test("B-60 plain HTTP is refused even for an allowed host")
    func rejectsPlainHTTPEvenForAllowedHosts() async {
        await #expect(throws: HTTPFailure.other("Host not allowed")) {
            try await client.send(HTTPRequest(.get, url: URL(string: "http://api.anthropic.com/api/oauth/usage")!, headers: [:]))
        }
    }

    @Test("B-24 a URL loading error, like a refused connection, reads as offline")
    func urlLoadingErrorsAreOffline() async {
        let local = URLSessionHTTPClient(allowedHosts: ["localhost"], log: RecordingDiagnosticsLog(), timeout: 2)
        await #expect(throws: HTTPFailure.offline) {
            try await local.send(HTTPRequest(.get, url: URL(string: "https://localhost:9/usage")!, headers: [:]))
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
