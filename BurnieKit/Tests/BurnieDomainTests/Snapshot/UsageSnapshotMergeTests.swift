import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageSnapshotMergeTests {
    static let meters = MeterSet(primary: Meter(id: .weekly, fill: Fraction(0.2), value: .percent(20), caption: .noActiveSession))
    static let cachedView = Stamped(LimitsPart(plan: PlanName(rawValue: "PRO"), meters: meters, unit: .money), at: .iso("2026-10-10T18:00:00Z"))
    static let cached = UsageSnapshot(provider: .alpha, content: .limits(view: cachedView, today: .tokens(Tokens(10))))

    @Test("B-17 a snapshot without limits keeps the cached limits part and its stamp")
    func activityOnlyKeepsTheCachedLimits() {
        let partial = UsageSnapshot(
            provider: .alpha,
            content: .activityOnly(Stamped(.tokens(Tokens(99)), at: .iso("2026-10-10T20:00:00Z"))),
            issue: .signInExpired
        )
        let shown = UsageSnapshot.merge(Self.cached, partial)
        #expect(shown == UsageSnapshot(provider: .alpha, content: .limits(view: Self.cachedView, today: .tokens(Tokens(99))), issue: .signInExpired))
        #expect(shown.fetchedAt == Self.cachedView.at)
    }

    @Test("B-17 a snapshot with limits replaces the cache")
    func limitsReplaceTheCache() {
        let fresh = UsageSnapshot(provider: .alpha, content: .limits(view: Stamped(Self.cachedView.value, at: .iso("2026-10-10T20:00:00Z")), today: nil))
        #expect(UsageSnapshot.merge(Self.cached, fresh) == fresh)
    }

    @Test("B-17 over a snapshot without limits, a snapshot without limits stays as it is")
    func withoutCachedLimitsTheSnapshotStays() {
        let earlier = UsageSnapshot(provider: .alpha, content: .activityOnly(Stamped(.tokens(Tokens(5)), at: .iso("2026-10-10T19:00:00Z"))))
        let partial = UsageSnapshot(provider: .alpha, content: .activityOnly(Stamped(.tokens(Tokens(99)), at: .iso("2026-10-10T20:00:00Z"))))
        #expect(UsageSnapshot.merge(earlier, partial) == partial)
    }

    @Test(arguments: Gen.seeds(200))
    func mergeIsAssociative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (a, b, c) = (gen.snapshot(), gen.snapshot(), gen.snapshot())
        let groupedLeft = UsageSnapshot.merge(UsageSnapshot.merge(a, b), c)
        let groupedRight = UsageSnapshot.merge(a, UsageSnapshot.merge(b, c))
        #expect(groupedLeft == groupedRight, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func mergeIsIdempotent(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        #expect(UsageSnapshot.merge(snapshot, snapshot) == snapshot, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func aSnapshotWithLimitsWins(seed: UInt64) {
        var gen = Gen(seed: seed)
        let previous = gen.snapshot()
        let next = UsageSnapshot(provider: gen.providerID(), content: .limits(view: gen.stamped { $0.limitsPart() }, today: nil))
        #expect(UsageSnapshot.merge(previous, next) == next, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func todayAndTheIssueComeFromTheRight(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (previous, next) = (gen.snapshot(), gen.snapshot())
        let shown = UsageSnapshot.merge(previous, next)
        #expect(shown.today == next.today, "seed \(seed)")
        #expect(shown.issue == next.issue, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func theLimitsPartIsNeverSplit(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (previous, next) = (gen.snapshot(), gen.snapshot())
        let shown = UsageSnapshot.merge(previous, next)
        let stampedLimits = { (snapshot: UsageSnapshot) -> Stamped<LimitsPart>? in
            guard case .limits(let view, _) = snapshot.content else { return nil }
            return view
        }
        #expect([stampedLimits(previous), stampedLimits(next)].contains(stampedLimits(shown)), "seed \(seed)")
    }
}
