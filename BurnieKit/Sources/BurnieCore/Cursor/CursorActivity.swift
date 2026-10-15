import Foundation

/// Cursor's activity source: tokens per day from the events CSV and today's spend from the usage events.
///
/// The spend is extra: if it can't be added up, the reading arrives without it and the header shows tokens.
public struct CursorActivity: ActivitySource {
    private let tokens: CursorEventsFetcher
    private let spend: CursorSpendFetcher

    public init(dashboard: CursorDashboardClient, clock: Clock) {
        tokens = CursorEventsFetcher(dashboard: dashboard, clock: clock)
        spend = CursorSpendFetcher(dashboard: dashboard, clock: clock)
    }

    public func activity() async throws(ProviderIssue) -> ActivityReading {
        let dailyTokens = try await tokens.dailyTokens()
        let spentCents = (try? await spend.dailySpentCents()) ?? [:]
        return ActivityReading(tokens: dailyTokens, spentCents: spentCents)
    }
}
