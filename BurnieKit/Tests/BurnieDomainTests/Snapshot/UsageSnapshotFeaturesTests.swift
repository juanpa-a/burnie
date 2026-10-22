import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageSnapshotFeaturesTests {
    static let onDemand = Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: Cents(1_000)), caption: .onDemandIdle)
    static let included = MeterSet(primary: Meter(id: .budget, fill: Fraction(0.4), value: .money(used: Cents(200), limit: Cents(500)), caption: .noActiveSession))

    static func snapshot(onDemand: Meter?) -> UsageSnapshot {
        let limits = LimitsPart(plan: PlanName(rawValue: "ENTERPRISE"), meters: included, unit: .money, features: SnapshotFeatures(onDemand: onDemand))
        return UsageSnapshot(provider: .alpha, content: .limits(view: Stamped(limits, at: .iso("2026-10-10T20:00:00Z")), today: .money(Cents(10))))
    }

    @Test("B-40 hiding on-demand removes only its meter")
    func hidingOnDemandKeepsEverythingElse() {
        #expect(Self.snapshot(onDemand: Self.onDemand).hiding([.onDemand]) == Self.snapshot(onDemand: nil))
    }

    @Test("B-40 hiding on-demand without it changes nothing")
    func hidingOnDemandWithoutItChangesNothing() {
        #expect(Self.snapshot(onDemand: nil).hiding([.onDemand]) == Self.snapshot(onDemand: nil))
    }

    @Test(arguments: Gen.seeds(200))
    func hidingNothingIsTheIdentity(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        #expect(snapshot.hiding([]) == snapshot, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func hidingTwiceIsHidingOnce(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        let toggles = Set(FeatureToggle.allCases.filter { _ in gen.coinFlip() })
        #expect(snapshot.hiding(toggles).hiding(toggles) == snapshot.hiding(toggles), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func hidingComposesByUnion(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        let first = Set(FeatureToggle.allCases.filter { _ in gen.coinFlip() })
        let second = Set(FeatureToggle.allCases.filter { _ in gen.coinFlip() })
        #expect(snapshot.hiding(first).hiding(second) == snapshot.hiding(first.union(second)), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func hidingCommutesWithMerge(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (previous, next) = (gen.snapshot(), gen.snapshot())
        let toggles = Set(FeatureToggle.allCases.filter { _ in gen.coinFlip() })
        let mergedThenHidden = UsageSnapshot.merge(previous, next).hiding(toggles)
        let hiddenThenMerged = UsageSnapshot.merge(previous.hiding(toggles), next.hiding(toggles))
        #expect(mergedThenHidden == hiddenThenMerged, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func hidingChangesOnlyTheFeatures(seed: UInt64) {
        var gen = Gen(seed: seed)
        let snapshot = gen.snapshot()
        let hidden = snapshot.hiding(Set(FeatureToggle.allCases))
        #expect(hidden.meters == snapshot.meters, "seed \(seed)")
        #expect(hidden.plan == snapshot.plan && hidden.unit == snapshot.unit, "seed \(seed)")
        #expect(hidden.today == snapshot.today && hidden.issue == snapshot.issue, "seed \(seed)")
        #expect(hidden.fetchedAt == snapshot.fetchedAt, "seed \(seed)")
    }
}
