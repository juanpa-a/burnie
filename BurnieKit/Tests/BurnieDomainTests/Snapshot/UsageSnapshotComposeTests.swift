import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageSnapshotComposeTests {
    static let limitsAt = Date.iso("2026-10-10T20:00:00Z")
    static let activityAt = Date.iso("2026-10-10T20:05:00Z")
    static let today = LocalDay.day("2026-10-10")
    static let meters = MeterSet(primary: Meter(id: .daily, fill: Fraction(0.64), value: .percent(64), caption: .noActiveSession))
    static let plan = LimitsPart(plan: PlanName(rawValue: "PRO"), meters: meters)
    static let tokens: [LocalDay: Tokens] = [today: Tokens(1_800_000), .day("2026-10-08"): Tokens(400)]
    static let activity = ActivityPart(tokens: tokens)
    static let missingScope = ProviderIssue.specific(SpecificIssue(code: "missingScope"))

    func compose(limits: Latest<LimitsPart>?, activity: Latest<ActivityPart>?) -> Result<UsageSnapshot, ProviderIssue> {
        UsageSnapshot.compose(provider: .alpha, limits: limits, activity: activity, today: Self.today)
    }

    func succeeded<Value>(_ value: Value, at date: Date) -> Latest<Value> {
        Latest(.success(value), at: date)
    }

    func failed<Value>(_ issue: ProviderIssue, at date: Date, after lastSuccess: Value? = nil) -> Latest<Value> {
        .failure(issue, at: date, lastSuccess: lastSuccess.map { Stamped($0, at: date.addingTimeInterval(-600)) })
    }

    @Test("B-10 limits and activity combine into one snapshot with meters and today's usage")
    func limitsAndActivityCombine() {
        let shown = compose(limits: succeeded(Self.plan, at: Self.limitsAt), activity: succeeded(Self.activity, at: Self.activityAt))
        let view = Stamped(Self.plan, at: Self.limitsAt)
        #expect(shown == .success(UsageSnapshot(provider: .alpha, content: .limits(view: view, today: TodayUsage(tokens: Tokens(1_800_000))))))
    }

    @Test("B-12 failed limits with activity give a snapshot without meters, with today's usage and the limits issue")
    func failedLimitsWithActivityIsPartial() {
        let shown = compose(limits: failed(Self.missingScope, at: Self.limitsAt), activity: succeeded(Self.activity, at: Self.activityAt))
        let usage = Stamped(TodayUsage(tokens: Tokens(1_800_000)), at: Self.activityAt)
        #expect(shown == .success(UsageSnapshot(provider: .alpha, content: .activityOnly(usage), issue: Self.missingScope)))
    }

    @Test("B-12 failed limits never bring back their last meters: merge does")
    func failedLimitsDoNotShowTheirLastSuccess() throws {
        let limits: Latest<LimitsPart> = failed(.offline, at: Self.limitsAt, after: Self.plan)
        let shown = try compose(limits: limits, activity: succeeded(Self.activity, at: Self.activityAt)).get()
        #expect(shown.meters == nil)
    }

    @Test("B-13 failed activity with limits gives meters without today's usage and without an issue")
    func failedActivityKeepsMetersWithoutToday() throws {
        let shown = try compose(limits: succeeded(Self.plan, at: Self.limitsAt), activity: failed(.notFound, at: Self.activityAt)).get()
        #expect(shown.meters == Self.meters)
        #expect(shown.today == nil)
        #expect(shown.issue == nil)
    }

    @Test("B-14 failed limits and failed activity give the limits issue")
    func bothFailedGiveTheLimitsIssue() {
        #expect(compose(limits: failed(.notFound, at: Self.limitsAt), activity: failed(.offline, at: Self.activityAt)) == .failure(.notFound))
    }

    @Test("B-14 failed limits before any activity give the limits issue")
    func failedLimitsBeforeAnyActivity() {
        #expect(compose(limits: failed(.signInExpired, at: Self.limitsAt), activity: nil) == .failure(.signInExpired))
    }

    @Test("B-14 failed activity before any limits gives the activity issue")
    func failedActivityBeforeAnyLimits() {
        #expect(compose(limits: nil, activity: failed(.offline, at: Self.activityAt)) == .failure(.offline))
    }

    @Test("B-14 before either part arrives there is nothing to show: not found")
    func nothingYetIsNotFound() {
        #expect(compose(limits: nil, activity: nil) == .failure(.notFound))
    }

    @Test("B-15 activity before any limits shows today's tokens alone, stamped when the activity arrived")
    func activityBeforeLimitsShowsTokensAlone() throws {
        let shown = try compose(limits: nil, activity: succeeded(Self.activity, at: Self.activityAt)).get()
        #expect(shown.content == .activityOnly(Stamped(TodayUsage(tokens: Tokens(1_800_000)), at: Self.activityAt)))
        #expect(shown.issue == nil)
    }

    @Test("B-15 a snapshot without limits is stamped when its activity arrived, not when the limits failed")
    func withoutLimitsTheStampIsTheActivitys() throws {
        let limitsFailedLater: Latest<LimitsPart> = failed(.offline, at: Self.activityAt.addingTimeInterval(300))
        let shown = try compose(limits: limitsFailedLater, activity: succeeded(Self.activity, at: Self.activityAt)).get()
        #expect(shown.fetchedAt == Self.activityAt)
    }

    @Test("B-16 a snapshot with limits is stamped when the limits arrived, even when the activity arrived later")
    func withLimitsTheStampIsTheLimits() throws {
        let shown = try compose(limits: succeeded(Self.plan, at: Self.limitsAt), activity: succeeded(Self.activity, at: Self.activityAt)).get()
        #expect(shown.fetchedAt == Self.limitsAt)
    }

    @Test(arguments: Gen.seeds(200))
    func composeIsTotal(seed: UInt64) {
        var gen = Gen(seed: seed)
        let limits = gen.maybe { $0.latest { $0.limitsPart() } }
        let activity = gen.maybe { $0.latest { $0.activityPart() } }
        let shown = UsageSnapshot.compose(provider: .alpha, limits: limits, activity: activity, today: Gen.referenceDay)
        let limitsSucceeded = if case .success? = limits { true } else { false }
        let activitySucceeded = if case .success? = activity { true } else { false }
        switch shown {
        case .success(let snapshot):
            #expect((snapshot.limits != nil) == limitsSucceeded, "seed \(seed)")
            #expect(limitsSucceeded || activitySucceeded, "seed \(seed)")
        case .failure:
            #expect(!limitsSucceeded && !activitySucceeded, "seed \(seed)")
        }
    }
}
