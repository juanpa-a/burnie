import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageSnapshotTests {
    static let limitsAt = Date.iso("2026-10-10T20:00:00Z")
    static let meters = MeterSet(primary: Meter(id: .daily, fill: Fraction(0.5), value: .percent(50), caption: .noActiveSession))
    static let onDemand = Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: nil), caption: .onDemandIdle)
    static let limits = LimitsPart(plan: PlanName(rawValue: "PRO"), meters: meters, features: SnapshotFeatures(onDemand: onDemand))

    @Test("B-16 a snapshot with limits reads its plan, meters and features from them")
    func limitsContentReadsTheLimitsPart() {
        let snapshot = UsageSnapshot(provider: .alpha, content: .limits(view: Stamped(Self.limits, at: Self.limitsAt), today: TodayUsage(tokens: Tokens(7))))
        #expect(snapshot.fetchedAt == Self.limitsAt)
        #expect(snapshot.plan == PlanName(rawValue: "PRO"))
        #expect(snapshot.meters == Self.meters)
        #expect(snapshot.features.onDemand == Self.onDemand)
        #expect(snapshot.today == TodayUsage(tokens: Tokens(7)))
    }

    @Test("B-15 a snapshot without limits has no plan, meters or features, and today's usage alone")
    func activityOnlyContentHasOnlyToday() {
        let snapshot = UsageSnapshot(provider: .alpha, content: .activityOnly(Stamped(TodayUsage(tokens: Tokens(7)), at: Self.limitsAt)))
        #expect(snapshot.fetchedAt == Self.limitsAt)
        #expect(snapshot.plan == nil && snapshot.meters == nil)
        #expect(snapshot.features == .empty)
        #expect(snapshot.today == TodayUsage(tokens: Tokens(7)))
    }

    @Test("B-6 a snapshot goes stale after 30 minutes")
    func goesStaleAfterThirtyMinutes() {
        let snapshot = UsageSnapshot(provider: .alpha, content: .activityOnly(Stamped(TodayUsage(tokens: .zero), at: Self.limitsAt)))
        #expect(!snapshot.isStale(at: Self.limitsAt.addingTimeInterval(30 * 60)))
        #expect(snapshot.isStale(at: Self.limitsAt.addingTimeInterval(30 * 60 + 1)))
    }
}
