import Foundation

/// Requests to the cursor.com dashboard's internal endpoints with the desktop app's session.
public struct CursorDashboardClient: Sendable {
    /// Cursor rejects the dashboard's POSTs without it, like any cross-site request.
    static let origin = "https://cursor.com"

    private let credentials: CursorCredentialsReader
    private let http: HTTPClient
    private let clock: Clock
    private let userAgent: String

    public init(credentials: CursorCredentialsReader, http: HTTPClient, clock: Clock, userAgent: String) {
        self.credentials = credentials
        self.http = http
        self.clock = clock
        self.userAgent = userAgent
    }

    func get(_ url: URL, accept: String) async throws(ProviderIssue) -> Data {
        try await send(.get, to: url, headers: ["Accept": accept])
    }

    func post(_ url: URL, json body: Data) async throws(ProviderIssue) -> Data {
        let headers = ["Accept": "application/json", "Content-Type": "application/json", "Origin": Self.origin]
        return try await send(.post(body), to: url, headers: headers)
    }

    private func send(_ method: HTTPRequest.Method, to url: URL, headers: [String: String]) async throws(ProviderIssue) -> Data {
        let token = try credentials.validToken(at: clock.now)
        let session = ["Cookie": token.sessionCookie, "User-Agent": userAgent]
        let request = HTTPRequest(method, url: url, headers: headers.merging(session) { _, session in session })
        return try await http.fetch(request, now: clock.now, classify: Self.issue)
    }

    /// 401, 403, a redirect, or HTML instead of data: the dashboard wants to send us to the login page.
    private static func issue(for response: HTTPURLResponse, body: Data) -> ProviderIssue? {
        switch response.statusCode {
        case 300..<400, 401, 403: .signInExpired
        case 200..<300 where response.mimeType == "text/html": .signInExpired
        default: nil
        }
    }
}
