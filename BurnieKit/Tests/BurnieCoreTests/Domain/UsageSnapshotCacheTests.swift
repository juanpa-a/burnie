import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct UsageSnapshotCacheTests {
    static let cached = UsageSnapshot(
        provider: .claude, fetchedAt: .iso("2026-10-10T18:00:00Z"), plan: "PRO", today: .tokens(10),
        meters: [Meter(id: .weekly, fraction: 0.2, value: .percent(20), caption: .noActiveSession)]
    )

    @Test("B-17 a snapshot without meters keeps the cached meters, plan and age")
    func partialSnapshotKeepsCachedMetersAndTheirAge() {
        let partial = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), today: .tokens(99), issue: .signInExpired)
        let shown = partial.keepingMeters(of: Self.cached)
        #expect(shown == UsageSnapshot(provider: .claude, fetchedAt: Self.cached.fetchedAt, plan: "PRO", today: .tokens(99), meters: Self.cached.meters, issue: .signInExpired))
    }

    @Test("B-17 a snapshot with meters replaces the cache")
    func snapshotWithMetersReplacesTheCache() {
        let fresh = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), meters: [Meter(id: .weekly, fraction: 0.3, value: .percent(30), caption: .noActiveSession)])
        #expect(fresh.keepingMeters(of: Self.cached) == fresh)
    }

    @Test("B-17 without a cache a snapshot without meters stays as it is")
    func withoutCacheTheSnapshotStaysAsIs() {
        let partial = UsageSnapshot(provider: .claude, fetchedAt: .iso("2026-10-10T20:00:00Z"), today: .tokens(99), issue: .missingScope)
        #expect(partial.keepingMeters(of: nil) == partial)
    }

    @Test("B-18 a total failure shows the cached snapshot with the issue on top")
    func totalFailureMarksTheCachedSnapshot() {
        #expect(Self.cached.with(issue: .offline).issue == .offline)
        #expect(Self.cached.with(issue: .offline).meters == Self.cached.meters)
    }

    // SPEC 4.4's merge laws on today's merge: `merge(previous, next)` is `next.keepingMeters(of: previous)`,
    // and a snapshot with meters stands for `.limits` content.

    @Test(arguments: Gen.seeds(200))
    func keepingMetersIsAssociative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let first = gen.snapshot()
        let second = gen.snapshot()
        let third = gen.snapshot()
        let groupedLeft = third.keepingMeters(of: second.keepingMeters(of: first))
        let groupedRight = third.keepingMeters(of: second).keepingMeters(of: first)
        #expect(groupedLeft == groupedRight, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func keepingMetersIsIdempotent(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        #expect(snapshot.keepingMeters(of: snapshot) == snapshot, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func keepingMetersIsRightBiased(seed: UInt64) {
        var gen = Gen(seed: seed)
        let cached = gen.snapshot()
        var fresh = gen.snapshot()
        fresh.meters.append(gen.meter())
        #expect(fresh.keepingMeters(of: cached) == fresh, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func keepingMetersTakesTodayAndIssueFromTheNewSnapshot(seed: UInt64) {
        var gen = Gen(seed: seed)
        let cached = gen.snapshot()
        let fresh = gen.snapshot()
        let shown = fresh.keepingMeters(of: cached)
        #expect(shown.today == fresh.today, "seed \(seed)")
        #expect(shown.issue == fresh.issue, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func keepingMetersNeverSplitsTheLimitsPart(seed: UInt64) {
        var gen = Gen(seed: seed)
        let cached = gen.snapshot()
        let fresh = gen.snapshot()
        let shown = limitsPart(of: fresh.keepingMeters(of: cached))
        #expect(shown == limitsPart(of: fresh) || shown == limitsPart(of: cached), "seed \(seed)")
    }

    /// What merging moves as one piece: the meters, their plan and their age.
    func limitsPart(of snapshot: UsageSnapshot) -> ([Meter], String?, Date) {
        (snapshot.meters, snapshot.plan, snapshot.fetchedAt)
    }
}
