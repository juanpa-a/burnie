import Foundation

/// Cursor's limits source: plan and meters from `usage-summary`.
public struct CursorSummaryFetcher: LimitsSource {
    // A literal URL, so it always parses.
    static let url = URL(string: "https://cursor.com/api/usage-summary")!

    private let dashboard: CursorDashboardClient

    public init(dashboard: CursorDashboardClient) {
        self.dashboard = dashboard
    }

    public func limits() async throws(ProviderIssue) -> LimitsReading {
        let body = try await dashboard.get(Self.url, accept: "application/json")
        guard let summary = try? JSONDecoder().decode(CursorUsageSummaryDTO.self, from: body) else {
            throw .unexpectedResponse("Cursor summary is not JSON")
        }
        return try CursorUsageMapper.limits(from: summary)
    }
}
