import BurnieDomain
import BurnieInterface
import Foundation

/// Reads from the cursor.com dashboard's internal endpoints with the desktop app's session: GETs only, with no
/// `Origin`, the header a browser adds (B-47).
struct CursorDashboardClient: Sendable {
    let credentials: CursorCredentialsReader
    let http: any HTTPClient
    let clock: any Clock
    let userAgent: String

    func get(_ url: URL, accept: String) async throws(ProviderIssue) -> Data {
        let headers = [
            "Accept": accept,
            "Cookie": try credentials.validToken(at: clock.now).sessionCookie,
            "User-Agent": userAgent,
        ]
        return try await http.fetch(HTTPRequest(url: url, headers: headers), now: clock.now, classify: Self.issue)
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
