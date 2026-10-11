import Foundation

/// GETs to the cursor.com dashboard's internal endpoints with the desktop app's session.
public struct CursorDashboardClient: Sendable {
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
        let token = try credentials.validToken(at: clock.now)
        let headers = ["Cookie": token.sessionCookie, "Accept": accept, "User-Agent": userAgent]
        return try await http.fetch(url, headers: headers, now: clock.now, classify: Self.issue)
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
