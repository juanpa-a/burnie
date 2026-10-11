import Foundation

/// A provider's source of tokens per local day: Claude's logs, Cursor's events CSV.
public protocol ActivitySource: Sendable {
    /// Covers at least today's `ActivityWindow.days(endingAt:)`.
    func dailyTokens() async throws(ProviderIssue) -> [LocalDay: Int]
}
