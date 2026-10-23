import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// What each provider shows, what the cache keeps, and what the history records, as runs finish.
extension RuntimeStateTests {
    static let cachedAlpha = UsageSnapshot(
        provider: .alpha,
        content: .limits(view: Stamped(TestProviders.alphaLimits, at: ReducerHarness.start.addingTimeInterval(-3_600)), today: TodayUsage(tokens: Tokens(900_000)))
    )

    /// Runs `key` with the Refresh button and finishes it with `outcome`, returning the effects of the finish.
    func refresh(_ harness: inout ReducerHarness, _ key: JobKey, with outcome: Result<Part, ProviderIssue>) -> [Effect] {
        let run = harness.send(.refreshRequested(harness.newRequest())).runs.first { $0.0 == key }!.1
        return harness.send(.taskFinished(key, run, outcome, jitter: 0))
    }

    @Test("B-10 a provider's limits and activity show as one snapshot, saved as shown")
    func partsShowAsOneSnapshot() throws {
        let harness = ReducerHarness.launched()
        let shown = try #require(harness.shown(.alpha))
        #expect(shown.meters == TestProviders.alphaMeters)
        #expect(shown.today == TodayUsage(tokens: Tokens(1_800_000)))
    }

    @Test("B-11 refreshing a provider's limits keeps its latest activity")
    func limitsRefreshKeepsTheActivity() throws {
        var harness = ReducerHarness.launched()
        let newLimits = LimitsPart(plan: PlanName(rawValue: "TEAMS"), meters: TestProviders.alphaMeters)
        _ = refresh(&harness, TestProviders.alphaLimitsJob, with: .success(.limits(newLimits)))
        let shown = try #require(harness.shown(.alpha))
        #expect(shown.plan == PlanName(rawValue: "TEAMS"))
        #expect(shown.today == TodayUsage(tokens: Tokens(1_800_000)))
    }

    @Test("B-11 refreshing a provider's activity keeps its latest limits")
    func activityRefreshKeepsTheLimits() throws {
        var harness = ReducerHarness.launched()
        _ = refresh(&harness, TestProviders.alphaActivityJob, with: .success(.activity(ActivityPart(tokens: [TestProviders.today: Tokens(2_000_000)]))))
        let shown = try #require(harness.shown(.alpha))
        #expect(shown.meters == TestProviders.alphaMeters)
        #expect(shown.today == TodayUsage(tokens: Tokens(2_000_000)))
    }

    @Test("B-17 B-19 failed limits keep the shown meters, and the cache saves the merged snapshot with its partial issue")
    func failedLimitsKeepTheShownMeters() throws {
        var harness = ReducerHarness.launched()
        let effects = refresh(&harness, TestProviders.alphaLimitsJob, with: .failure(.signInExpired))
        let shown = try #require(harness.shown(.alpha))
        #expect(shown.meters == TestProviders.alphaMeters)
        #expect(shown.issue == .signInExpired)
        #expect(effects.contains(.saveSnapshot(shown)))
    }

    @Test("B-18 a total failure over a cached snapshot shows the cache with the issue on top")
    func totalFailureShowsTheCacheWithTheIssue() {
        let failed: [JobKey: Result<Part, ProviderIssue>] = [
            TestProviders.alphaLimitsJob: .failure(.notFound), TestProviders.alphaActivityJob: .failure(.notFound),
        ]
        let harness = ReducerHarness.launched(cached: [.alpha: Self.cachedAlpha], finishing: failed)
        var withIssue = Self.cachedAlpha
        withIssue.issue = .notFound
        #expect(harness.state.shown[.alpha] == .ready(withIssue))
    }

    @Test("B-18 a total failure without a cache shows the failure alone")
    func totalFailureWithoutACacheFails() {
        let failed: [JobKey: Result<Part, ProviderIssue>] = [
            TestProviders.alphaLimitsJob: .failure(.notFound), TestProviders.alphaActivityJob: .failure(.notFound),
        ]
        let harness = ReducerHarness.launched(finishing: failed)
        #expect(harness.state.shown[.alpha] == .failed(.notFound))
    }

    @Test("B-19 a total failure saves nothing, so the cache keeps the last good snapshot")
    func totalFailureSavesNothing() {
        var harness = ReducerHarness()
        let runs = harness.send(.launched(settings: .defaults(enabled: [.alpha]), cached: [.alpha: Self.cachedAlpha], history: UsageHistory())).runs
        let saves = runs.flatMap { key, run in harness.send(.taskFinished(key, run, .failure(.notFound), jitter: 0)) }
            .filter { if case .saveSnapshot = $0 { true } else { false } }
        #expect(saves.isEmpty)
    }

    @Test("B-42 each activity records the history's window and saves it")
    func activityRecordsTheHistory() {
        var harness = ReducerHarness.launched()
        let effects = refresh(&harness, TestProviders.alphaActivityJob, with: .success(.activity(ActivityPart(tokens: [TestProviders.today: Tokens(2_000_000)]))))
        let week = harness.state.history.points(for: .alpha, endingAt: TestProviders.today, count: 3).map(\.tokens.count)
        #expect(week == [0, 0, 2_000_000])
        #expect(effects.contains(.saveHistory(harness.state.history)))
    }

    @Test("B-42 a failed activity leaves the history as it was")
    func failedActivityKeepsTheHistory() {
        var harness = ReducerHarness.launched()
        let before = harness.state.history
        let effects = refresh(&harness, TestProviders.alphaActivityJob, with: .failure(.notFound))
        #expect(harness.state.history == before)
        #expect(!effects.contains(.saveHistory(before)))
    }

    @Test("B-51 a run that finishes after its provider was turned off, or off and on, is dropped")
    func lateRunsAreDropped() throws {
        var harness = ReducerHarness()
        let runs = harness.send(.launched(settings: .defaults(enabled: [.alpha]), cached: [:], history: UsageHistory())).runs
        harness.send(.providerToggled(.alpha, isOn: false))
        let (key, run) = try #require(runs.first)
        #expect(harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0)).isEmpty)
        #expect(harness.state.shown[.alpha] == .loading)

        let fresh = harness.send(.providerToggled(.alpha, isOn: true)).runs
        #expect(harness.send(.taskFinished(key, run, .failure(.offline), jitter: 0)).isEmpty)
        #expect(harness.state.jobs[key]?.running == fresh.first?.1)
    }
}
