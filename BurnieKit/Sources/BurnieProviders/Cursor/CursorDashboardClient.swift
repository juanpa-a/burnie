import BurnieDomain
import BurnieInterface
import Foundation

/// Requests to the cursor.com dashboard's internal endpoints with the desktop app's session.
struct CursorDashboardClient: Sendable {
    /// Cursor rejects the dashboard's POSTs without it, like any cross-site request.
    private static let origin = "https://cursor.com"

    let credentials: CursorCredentialsReader
    let http: any HTTPClient
    let clock: any Clock
    let userAgent: String

    func get(_ url: URL, accept: String) async throws(ProviderIssue) -> Data {
        try await send(.get, to: url, headers: ["Accept": accept])
    }

    func post(_ url: URL, json body: Data) async throws(ProviderIssue) -> Data {
        let headers = ["Accept": "application/json", "Content-Type": "application/json", "Origin": Self.origin]
        return try await send(.post(body), to: url, headers: headers)
    }

    private func send(_ method: HTTPRequest.Method, to url: URL, headers: [String: String]) async throws(ProviderIssue) -> Data {
        var headers = headers
        headers["Cookie"] = try credentials.validToken(at: clock.now).sessionCookie
        headers["User-Agent"] = userAgent
        return try await http.fetch(HTTPRequest(method, url: url, headers: headers), now: clock.now, classify: Self.issue)
    }

    /// 401, 403, a redirect, or HTML instead of data: the dashboard wants to send us to the login page (B-26).
    private static func issue(for response: HTTPResponse) -> ProviderIssue? {
        switch response.status {
        case 300..<400, 401, 403: .signInExpired
        case 200..<300 where response.mimeType == "text/html": .signInExpired
        default: nil
        }
    }
}
