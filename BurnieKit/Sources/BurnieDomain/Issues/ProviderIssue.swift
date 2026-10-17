import Foundation

/// Why a provider can't show something. The common cases are shared; a provider adds its own as `specific`.
public enum ProviderIssue: Error, Hashable, Sendable {
    /// The provider's app isn't installed or never signed in.
    case notFound
    /// The sign-in expired or was refused.
    case signInExpired
    case rateLimited(retryAt: Date?)
    case offline
    /// For the logs only; the UI shows the common unexpected copy.
    case unexpectedResponse(String)
    /// An issue only one provider has; its copy lives in that provider's descriptor.
    case specific(SpecificIssue)
}
