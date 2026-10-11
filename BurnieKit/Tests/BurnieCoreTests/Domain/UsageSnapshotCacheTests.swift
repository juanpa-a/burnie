import Foundation
import Testing
@testable import BurnieCore

struct UsageSnapshotCacheTests {
    static let cached = UsageSnapshot(
        provider: .claude, fetchedAt: .iso("2026-10-10T18:00:00Z"), plan: "PRO", tokensToday: 10,
        meters: [Meter(id: .weekly, fraction: 0.2, value: .percent(20), caption: .noActiveSession)]
    )

    @Test func partialSnapshotKeepsCachedMetersAndTheirAge() {
        let partial = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), tokensToday: 99, issue: .signInExpired)
        let shown = partial.keepingMeters(of: Self.cached)
        #expect(shown == UsageSnapshot(provider: .claude, fetchedAt: Self.cached.fetchedAt, plan: "PRO", tokensToday: 99, meters: Self.cached.meters, issue: .signInExpired))
    }

    @Test func snapshotWithMetersReplacesTheCache() {
        let fresh = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), meters: [Meter(id: .weekly, fraction: 0.3, value: .percent(30), caption: .noActiveSession)])
        #expect(fresh.keepingMeters(of: Self.cached) == fresh)
    }

    @Test func withoutCacheTheSnapshotStaysAsIs() {
        let partial = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), tokensToday: 99, issue: .missingScope)
        #expect(partial.keepingMeters(of: nil) == partial)
    }

    @Test func totalFailureMarksTheCachedSnapshot() {
        #expect(Self.cached.with(issue: .offline).issue == .offline)
        #expect(Self.cached.with(issue: .offline).meters == Self.cached.meters)
    }
}
