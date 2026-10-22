import BurnieDomain
import Foundation

/// The text of a section's issue row.
public enum IssueMessage {
    /// What every provider shows for an answer Burnie couldn't read, or a specific issue without copy (B-21).
    static let unexpected = "Couldn't read usage. Burnie may need an update."

    /// nil when no row is shown: on a rate limit or offline the cached data stays and the header already says how old
    /// it is (B-20). The rest comes from the provider's copy (B-21).
    public static func message(for issue: ProviderIssue, copy: ProviderCopy) -> String? {
        switch issue {
        case .rateLimited, .offline: nil
        case .notFound: copy.notFound
        case .signInExpired: copy.signInExpired
        case .specific(let specific): copy.specific[specific] ?? unexpected
        case .unexpectedResponse: unexpected
        }
    }
}
