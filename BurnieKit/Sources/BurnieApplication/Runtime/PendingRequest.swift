import Foundation

/// An open refresh request: open until every run it started finishes, and, for a sign-in renewal, until the provider's
/// app is done. The Refresh spinner shows while any is open (B-59).
struct PendingRequest: Equatable, Sendable {
    /// The runs it started that haven't finished.
    var runs: Set<RunID> = []
    /// Only a sign-in renewal: the provider's app is still running.
    var isRenewing = false
    /// What a sign-in renewal returns; true for the others.
    var result = true

    var isDone: Bool {
        runs.isEmpty && !isRenewing
    }
}
