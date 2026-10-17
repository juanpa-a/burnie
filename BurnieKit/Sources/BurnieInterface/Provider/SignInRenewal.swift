import Foundation

/// A capability: the provider's own app renews an expired sign-in, so Burnie never touches another app's credentials
/// (B-61).
public struct SignInRenewal: Sendable {
    /// The issue row's text when `run` returns false (B-22).
    public let failedCopy: String
    /// True once the provider's app renewed the sign-in.
    public let run: @Sendable () async -> Bool

    public init(failedCopy: String, run: @escaping @Sendable () async -> Bool) {
        self.failedCopy = failedCopy
        self.run = run
    }
}
