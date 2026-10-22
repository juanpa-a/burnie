import Foundation

/// Response of `api/oauth/profile`; only the organization's plan. Decoded with `.convertFromSnakeCase`.
struct ClaudeProfileDTO: Decodable {
    struct Organization: Decodable {
        /// "claude_max", "claude_pro"…
        let organizationType: String?
    }

    let organization: Organization?
}
