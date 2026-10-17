import BurnieDomain
import BurnieInterface
import Foundation

/// Cursor's limits: plan, meters and on-demand from `usage-summary`.
struct CursorSummaryFetcher: Sendable {
    // A literal URL, so it always parses.
    static let url = URL(string: "https://cursor.com/api/usage-summary")!

    let dashboard: CursorDashboardClient

    func limits() async throws(ProviderIssue) -> LimitsPart {
        let body = try await dashboard.get(Self.url, accept: "application/json")
        guard let summary = try? JSONDecoder().decode(CursorUsageSummaryDTO.self, from: body) else {
            throw .unexpectedResponse("Cursor summary is not JSON")
        }
        return try CursorUsageMapper.limits(from: summary)
    }
}
