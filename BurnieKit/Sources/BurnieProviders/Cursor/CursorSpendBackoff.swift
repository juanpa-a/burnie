import BurnieDomain
import Foundation

/// The spend's own wait after a 429, kept between activity refreshes: the activity keeps its tokens meanwhile, and the
/// spend isn't asked for again before its `retryAt` (B-47). A memo (P-5): losing it costs at most one more request.
actor CursorSpendBackoff {
    private var backoff = RateLimitBackoff()

    /// While the last 429's wait lasts, throws it again instead of letting the spend be asked for.
    func checkWaitIsOver(at now: Date) throws(ProviderIssue) {
        guard backoff.allowsRequest(at: now) else { throw .rateLimited(retryAt: backoff.retryAt) }
    }

    func record<Value>(_ outcome: Result<Value, ProviderIssue>, at now: Date) {
        backoff.record(outcome, now: now)
    }
}
