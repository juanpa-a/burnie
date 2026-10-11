import Foundation
import Testing
@testable import BurnieCore

struct CompositeUsageProviderTests {
    static let now = Date.iso("2026-10-10T20:00:00Z")
    static let reading = LimitsReading(plan: "PRO", meters: [Meter(id: .session, fraction: 0.64, value: .percent(64), caption: .noActiveSession)])
    static let tokens: [LocalDay: Int] = [.day("2026-10-10"): 1_800_000, .day("2026-10-08"): 400]

    let limits = FakeLimitsSource(.success(reading))
    let activity = FakeActivitySource(.success(tokens))

    var provider: CompositeUsageProvider {
        CompositeUsageProvider(id: .claude, limits: limits, activity: activity, clock: FixedClock(now: Self.now))
    }

    @Test func combinesMetersWithTodaysTokens() async throws {
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, plan: "PRO", tokensToday: 1_800_000, meters: Self.reading.meters))
    }

    @Test func refreshesOnlyTheRequestedSource() async throws {
        let provider = provider
        _ = try await provider.snapshot(refreshing: [.limits, .activity])
        let snapshot = try await provider.snapshot(refreshing: [.activity])
        #expect(limits.calls == 1)
        #expect(activity.calls == 2)
        #expect(snapshot.meters == Self.reading.meters) // remembered from the first refresh
    }

    @Test func failedLimitsWithActivityIsAPartialSnapshot() async throws {
        limits.set(.failure(.missingScope))
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, tokensToday: 1_800_000, issue: .missingScope))
    }

    @Test func failedActivityKeepsMetersWithoutTokens() async throws {
        activity.set(.failure(.notFound))
        let snapshot = try await provider.snapshot(refreshing: [.limits, .activity])
        #expect(snapshot.meters == Self.reading.meters)
        #expect(snapshot.tokensToday == nil)
        #expect(snapshot.issue == nil)
    }

    @Test func nothingToShowThrowsTheLimitsIssue() async {
        limits.set(.failure(.notFound))
        activity.set(.failure(.offline))
        await #expect(throws: ProviderIssue.notFound) { try await provider.snapshot(refreshing: [.limits, .activity]) }
    }

    @Test func activityBeforeLimitsShowsTokensAlone() async throws {
        let snapshot = try await provider.snapshot(refreshing: [.activity])
        #expect(snapshot == UsageSnapshot(provider: .claude, fetchedAt: Self.now, tokensToday: 1_800_000))
        #expect(limits.calls == 0)
    }

    @Test func historyFillsMissingDaysWithZeroAndEndsToday() async throws {
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
