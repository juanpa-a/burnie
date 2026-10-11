import Foundation

public enum ProviderIssue: Error, Codable, Sendable, Equatable {
    /// The app isn't installed or never signed in.
    case notFound
    /// Expired token or 401/403.
    case signInExpired
    /// Token without `user:profile` (`claude setup-token`).
    case missingScope
    case rateLimited(retryAt: Date?)
    case offline
    /// Logs only; the UI shows generic text.
    case unexpectedResponse(String)
}
