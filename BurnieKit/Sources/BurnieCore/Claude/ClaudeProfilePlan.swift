import Foundation

/// The plan chip according to `api/oauth/profile`.
///
/// Claude Code's credentials keep the plan from sign-in time and don't change when the
/// subscription changes; the profile does. Since the plan rarely changes, it's requested at most once an hour.
actor ClaudeProfilePlan {
    static let url = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    static let maxAge: TimeInterval = 60 * 60

    private let http: HTTPClient
    private var cached: (chip: String?, fetchedAt: Date)?

    init(http: HTTPClient) {
        self.http = http
    }

    /// nil if the profile never answered or reports an unknown plan. If a request fails, it keeps the last one that arrived.
    func chip(headers: [String: String], now: Date) async -> String? {
        if let cached, now.timeIntervalSince(cached.fetchedAt) < Self.maxAge {
            return cached.chip
        }
        if let organization = await organization(headers: headers, now: now) {
            cached = (ClaudePlanChip.label(plan: organization.organizationType), now)
        }
        return cached?.chip
    }

    private func organization(headers: [String: String], now: Date) async -> ClaudeProfileDTO.Organization? {
        let request = HTTPRequest(.get, url: Self.url, headers: headers)
        guard let body = try? await http.fetch(request, now: now, classify: { _, _ in nil }) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try? decoder.decode(ClaudeProfileDTO.self, from: body))?.organization
    }
}
