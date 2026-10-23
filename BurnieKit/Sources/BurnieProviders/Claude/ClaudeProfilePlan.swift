import BurnieDomain
import BurnieInterface
import Foundation

/// A memo of the plan chip according to `api/oauth/profile` (B-28, P-5).
///
/// Claude Code's credentials keep the plan from sign-in time and don't change when the subscription changes; the
/// profile does. Since the plan rarely changes, it's requested at most once an hour.
actor ClaudeProfilePlan {
    // A literal URL, so it always parses.
    static let url = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    static let maxAge: TimeInterval = 60 * 60

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let http: any HTTPClient
    private var cached: (chip: PlanName?, fetchedAt: Date)?

    init(http: any HTTPClient) {
        self.http = http
    }

    /// nil if the profile never answered or reports an unknown plan. If a request fails, it keeps the last one that
    /// arrived.
    func chip(headers: [String: String], now: Date) async -> PlanName? {
        if let cached, now.timeIntervalSince(cached.fetchedAt) < Self.maxAge {
            return cached.chip
        }
        if let organization = await organization(headers: headers, now: now) {
            cached = (ClaudePlanChip.label(plan: organization.organizationType), now)
        }
        return cached?.chip
    }

    private func organization(headers: [String: String], now: Date) async -> ClaudeProfileDTO.Organization? {
        let request = HTTPRequest(url: Self.url, headers: headers)
        guard let body = try? await http.fetch(request, now: now, classify: { _ in nil }) else { return nil }
        return (try? Self.decoder.decode(ClaudeProfileDTO.self, from: body))?.organization
    }
}
