import Foundation

/// A provider's source of usage per local day: Claude's logs, Cursor's events.
public protocol ActivitySource: Sendable {
    /// Tokens cover at least today's `ActivityWindow.days(endingAt:)`.
    func activity() async throws(ProviderIssue) -> ActivityReading
}
