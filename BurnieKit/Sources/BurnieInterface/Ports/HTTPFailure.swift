import Foundation

/// Why the HTTP port got no response.
public enum HTTPFailure: Error, Hashable, Sendable {
    /// Any URL loading error: no network, a timeout, a refused host (B-24, B-70).
    case offline
    /// Anything else, described for the logs only.
    case other(String)
}
