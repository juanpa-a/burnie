import Foundation

extension UsageSnapshot {
    /// Older than this, the UI dims the values (B-6).
    public static let staleAfter: TimeInterval = 30 * 60

    public func isStale(at now: Date) -> Bool {
        now.timeIntervalSince(fetchedAt) > Self.staleAfter
    }
}
