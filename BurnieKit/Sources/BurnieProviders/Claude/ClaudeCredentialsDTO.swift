import Foundation

/// The `Claude Code-credentials` payload. Only `claudeAiOauth` is used.
struct ClaudeCredentialsDTO: Decodable {
    struct OAuth: Decodable {
        let accessToken: String
        /// Epoch in milliseconds.
        let expiresAt: Double?
        /// "pro", "max", "team", "enterprise"
        let subscriptionType: String?

        func isExpired(at now: Date) -> Bool {
            guard let expiresAt else { return false }
            return Date(timeIntervalSince1970: expiresAt / 1_000) <= now
        }
    }

    let claudeAiOauth: OAuth?
}
