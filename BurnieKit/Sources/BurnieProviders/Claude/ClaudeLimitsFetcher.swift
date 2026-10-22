import BurnieDomain
import BurnieInterface
import Foundation

/// Claude's limits: the session and weekly meters from the OAuth usage endpoint, and the plan from the profile.
///
/// Burnie never refreshes the token: rotating the refresh token alongside Claude Code can invalidate its session (B-61).
struct ClaudeLimitsFetcher: Sendable {
    // A literal URL, so it always parses.
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let credentials: ClaudeCredentialsReader
    private let http: any HTTPClient
    private let profilePlan: ClaudeProfilePlan
    private let clock: any Clock
    private let userAgent: String

    init(credentials: ClaudeCredentialsReader, http: any HTTPClient, clock: any Clock, userAgent: String) {
        self.credentials = credentials
        self.http = http
        profilePlan = ClaudeProfilePlan(http: http)
        self.clock = clock
        self.userAgent = userAgent
    }

    /// An expired token is caught before any request (B-25).
    func limits() async throws(ProviderIssue) -> LimitsPart {
        let oauth = try credentials.oauth()
        guard !oauth.isExpired(at: clock.now) else { throw .signInExpired }
        let headers = headers(accessToken: oauth.accessToken)
        let body = try await http.fetch(HTTPRequest(.get, url: Self.usageURL, headers: headers), now: clock.now, classify: Self.issue)
        guard let usage = try? Self.decoder.decode(ClaudeUsageDTO.self, from: body) else {
            throw .unexpectedResponse("Claude usage is not JSON")
        }
        let meters = try ClaudeUsageMapper.meters(from: usage)
        // The credentials' plan may be the one from sign-in time: it's only used when the profile doesn't answer.
        let plan = await profilePlan.chip(headers: headers, now: clock.now)
            ?? ClaudePlanChip.label(plan: oauth.subscriptionType)
        return LimitsPart(plan: plan, meters: meters)
    }

    private func headers(accessToken: String) -> [String: String] {
        [
            "Authorization": "Bearer \(accessToken)",
            "anthropic-beta": "oauth-2025-04-20",
            "Accept": "application/json",
            "User-Agent": userAgent,
        ]
    }

    /// 401 → sign-in expired; 403 for a missing `user:profile` → missing scope; any other 403 → sign-in expired (B-25).
    private static func issue(for response: HTTPResponse) -> ProviderIssue? {
        switch response.status {
        case 401:
            return .signInExpired
        case 403:
            let message = (try? JSONDecoder().decode(ClaudeErrorDTO.self, from: response.body))?.error?.message ?? ""
            return message.contains("user:profile") ? .specific(.missingScope) : .signInExpired
        default:
            return nil
        }
    }
}
