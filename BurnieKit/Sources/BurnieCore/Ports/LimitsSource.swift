import Foundation

/// A provider's source of meters and plan: Claude's OAuth, Cursor's usage-summary.
public protocol LimitsSource: Sendable {
    func limits() async throws(ProviderIssue) -> LimitsReading
}
