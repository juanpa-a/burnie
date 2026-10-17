import BurnieDomain
import Foundation

/// A provider's own user-visible text: its issue rows and its healthy status line.
public struct ProviderCopy: Sendable {
    /// The issue row when the provider's app isn't installed or never signed in.
    public let notFound: String
    /// The issue row when the sign-in expired.
    public let signInExpired: String
    /// The issue rows of the provider's specific issues; a code without copy reads as the common unexpected one.
    public let specific: [SpecificIssue: String]
    /// The status line on the providers screen while nothing is wrong.
    public let status: @Sendable (StatusContext) -> String

    public init(
        notFound: String,
        signInExpired: String,
        specific: [SpecificIssue: String] = [:],
        status: @escaping @Sendable (StatusContext) -> String
    ) {
        self.notFound = notFound
        self.signInExpired = signInExpired
        self.specific = specific
        self.status = status
    }
}
