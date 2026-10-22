import BurnieDomain
import BurnieInterface
import Foundation

/// Cursor's activity: tokens per day from the events CSV, and each day's spend from the usage events, in one part.
///
/// The spend is extra: when it can't be added up, a 429 included, the part arrives without it and the header reads
/// tokens; it never fails the part nor starts a backoff (B-47).
struct CursorActivity: Sendable {
    let tokens: CursorEventsFetcher
    let spend: CursorSpendFetcher

    func activity() async throws(ProviderIssue) -> ActivityPart {
        let dailyTokens = try await tokens.dailyTokens()
        let spent = (try? await spend.dailySpentCents()) ?? [:]
        return ActivityPart(tokens: dailyTokens, spent: spent)
    }
}
