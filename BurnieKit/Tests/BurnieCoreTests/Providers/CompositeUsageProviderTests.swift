import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

struct CompositeUsageProviderTests {
    static let now = Date.iso("2026-10-10T20:00:00Z")
    static let reading = LimitsReading(plan: "PRO", meters: [Meter(id: .session, fraction: 0.64, value: .percent(64), caption: .noActiveSession)])
    static let budget = LimitsReading(plan: "ENTERPRISE", meters: [Meter(id: .included, fraction: 0.37, value: .money(usedCents: 18_420, limitCents: 50_000), caption: .noActiveSession)], unit: .money)
    static let tokens: [LocalDay: Int] = [.day("2026-10-10"): 1_800_000, .day("2026-10-08"): 400]
    static let spentToday: [LocalDay: Int] = [.day("2026-10-10"): 1_240]

    let limits = FakeLimitsSource(.success(reading))
    let activity = FakeActivitySource(.success(ActivityReading(tokens: tokens)))

    var provider: CompositeUsageProvider {
        CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: FixedClock(now: Self.now))
    }

    @Test("B-10 limits and activity combine into one snapshot with meters and today's usage")
    func combinesMetersWithTodaysTokens() async throws {
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, plan: "PRO", today: .tokens(1_800_000), meters: Self.reading.meters))
    }

    @Test("B-11 refreshing one source keeps the latest result of the other")
    func refreshesOnlyTheRequestedSource() async throws {
        let provider = provider
        _ = try await provider.snapshot(refreshing: [.limits, .activity])
        let snapshot = try await provider.snapshot(refreshing: [.activity])
        #expect(limits.calls == 1)
        #expect(activity.calls == 2)
        #expect(snapshot.meters == Self.reading.meters) // remembered from the first refresh
    }

    @Test("B-12 failed limits with activity give a snapshot without meters, with today's usage and the limits issue")
    func failedLimitsWithActivityIsAPartialSnapshot() async throws {
        limits.set(.failure(.missingScope))
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, today: .tokens(1_800_000), issue: .missingScope))
    }

    @Test("B-13 failed activity with limits gives meters without today's usage and without an issue")
    func failedActivityKeepsMetersWithoutToday() async throws {
        activity.set(.failure(.notFound))
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot.meters == Self.reading.meters)
        #expect(snapshot.today == nil)
        #expect(snapshot.issue == nil)
    }

    @Test("B-14 failed limits and failed activity throw the limits issue")
    func nothingToShowThrowsTheLimitsIssue() async {
        limits.set(.failure(.notFound))
        activity.set(.failure(.offline))
        await #expect(throws: ProviderIssue.notFound) { try await provider.snapshot(refreshing: [.limits, .activity]) }
    }

    @Test("B-14 failed limits before any activity throw the limits issue")
    func failedLimitsBeforeAnyActivityThrowTheLimitsIssue() async {
        limits.set(.failure(.signInExpired))
        await #expect(throws: ProviderIssue.signInExpired) { try await provider.snapshot(refreshing: [.limits]) }
    }

    @Test("B-14 failed activity before any limits throws the activity issue")
    func failedActivityBeforeAnyLimitsThrowsTheActivityIssue() async {
        activity.set(.failure(.offline))
        await #expect(throws: ProviderIssue.offline) { try await provider.snapshot(refreshing: [.activity]) }
    }

    @Test("B-14 before either source answers there is nothing to show: not found")
    func nothingRefreshedYetIsNotFound() async {
        await #expect(throws: ProviderIssue.notFound) { try await provider.snapshot(refreshing: []) }
    }

    @Test("B-15 activity before any limits shows today's tokens alone")
    func activityBeforeLimitsShowsTokensAlone() async throws {
        let snapshot = try await provider.snapshot(refreshing: [.activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, today: .tokens(1_800_000)))
        #expect(limits.calls == 0)
    }

    @Test("B-15 a snapshot without limits is stamped when its activity arrived, not when the limits failed")
    func snapshotWithoutLimitsCarriesTheActivitysTime() async throws {
        let clock = ManualClock(now: Self.now)
        let provider = CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: clock)
        _ = try await provider.snapshot(refreshing: [.activity])

        clock.advance(by: 5 * 60)
        limits.set(.failure(.offline))
        #expect(try await provider.snapshot(refreshing: [.limits]).fetchedAt == Self.now)
    }

    @Test("B-16 a snapshot with limits is stamped when the limits arrived, even when the activity arrived later")
    func snapshotWithLimitsCarriesTheLimitsTime() async throws {
        let clock = ManualClock(now: Self.now)
        let provider = CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: clock)
        _ = try await provider.snapshot(refreshing: [.limits, .activity])

        clock.advance(by: 5 * 60)
        activity.set(.success(ActivityReading(tokens: [.day("2026-10-10"): 2_000_000])))
        let snapshot = try await provider.snapshot(refreshing: [.activity])
        #expect(snapshot.fetchedAt == Self.now)
        #expect(snapshot.today == .tokens(2_000_000))
    }

    @Test("B-7 a dollar budget with today's spend reads money")
    func aDollarBudgetShowsTodaysSpend() async throws {
        limits.set(.success(Self.budget))
        activity.set(.success(ActivityReading(tokens: Self.tokens, spentCents: Self.spentToday)))
        #expect(try await provider.snapshot(refreshing: [.limits, .activity]).today == .money(cents: 1_240))
    }

    @Test("B-7 a dollar budget without today's spend reads tokens")
    func aDollarBudgetWithoutSpendFallsBackToTokens() async throws {
        limits.set(.success(Self.budget))
        #expect(try await provider.snapshot(refreshing: [.limits, .activity]).today == .tokens(1_800_000))
    }

    @Test("B-7 a token plan reads tokens even with spend")
    func tokenPlansIgnoreSpend() async throws {
        activity.set(.success(ActivityReading(tokens: Self.tokens, spentCents: Self.spentToday)))
        #expect(try await provider.snapshot(refreshing: [.limits, .activity]).today == .tokens(1_800_000))
    }

    @Test("B-8 failed limits keep the unit of the last successful ones")
    func failedLimitsKeepTheLastUnit() async throws {
        limits.set(.success(Self.budget))
        activity.set(.success(ActivityReading(tokens: Self.tokens, spentCents: Self.spentToday)))
        let provider = provider
        _ = try await provider.snapshot(refreshing: [.limits, .activity])
        limits.set(.failure(.offline))
        #expect(try await provider.snapshot(refreshing: [.limits]).today == .money(cents: 1_240))
    }

    @Test("B-42 history fills the days the activity doesn't mention with 0 and ends today")
    func historyFillsMissingDaysWithZeroAndEndsToday() async throws {
        let provider = provider
        _ = try await provider.snapshot(refreshing: [.activity])
        let points = try await provider.history(days: 3)
        #expect(points == [
            DailyPoint(day: .day("2026-10-08"), value: 400),
            DailyPoint(day: .day("2026-10-09"), value: 0),
            DailyPoint(day: .day("2026-10-10"), value: 1_800_000),
        ])
    }

    @Test func historyThrowsTheActivityIssue() async throws {
        activity.set(.failure(.rateLimited(retryAt: nil)))
        let provider = provider
        _ = try await provider.snapshot(refreshing: [.limits, .activity])
        await #expect(throws: ProviderIssue.rateLimited(retryAt: nil)) { try await provider.history(days: 7) }
    }
}
