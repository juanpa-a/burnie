import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// Each job's timer, its backoff after a 429, and what a timer firing does.
extension RuntimeStateTests {
    /// Fires the timer of `key` once its delay passed, finishes the run it starts with `outcome`, and returns how long
    /// the next timer waits.
    func fireAndFinish(_ harness: inout ReducerHarness, _ key: JobKey, with outcome: Result<Part, ProviderIssue>) -> TimeInterval? {
        guard let timer = harness.timer(of: key), let delay = harness.state.jobs[key].map({ Scheduling.delay(for: $0, now: harness.now, jitter: 0) }) else { return nil }
        harness.advance(by: delay)
        guard let (_, run) = harness.send(.timerFired(key, timer)).runs.first else { return nil }
        return harness.send(.taskFinished(key, run, outcome, jitter: 0)).timerDelays[key]
    }

    @Test("B-35 without a backoff, the next timer waits the job's interval, moved by the jitter sample")
    func timerWaitsTheInterval() {
        var harness = ReducerHarness()
        let runs = harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [:], history: UsageHistory())).runs
        let delays = runs.reduce(into: [JobKey: TimeInterval]()) { delays, job in
            let outcome = ReducerHarness.healthyOutcomes[job.0]!
            delays.merge(harness.send(.taskFinished(job.0, job.1, outcome, jitter: 1)).timerDelays) { $1 }
        }
        #expect(delays == [
            TestProviders.alphaLimitsJob: 330, TestProviders.alphaActivityJob: 300,
            TestProviders.betaLimitsJob: 630, TestProviders.betaActivityJob: 1_800,
        ])
    }

    @Test("B-33 after a 429, nothing is requested from that job before retryAt, not even with Refresh")
    func rateLimitedJobWaitsForRetryAt() {
        let retryAt = ReducerHarness.start.addingTimeInterval(120)
        var outcomes = ReducerHarness.healthyOutcomes
        outcomes[TestProviders.betaLimitsJob] = .failure(.rateLimited(retryAt: retryAt))
        var harness = ReducerHarness.launched(finishing: outcomes)
        #expect(harness.state.jobs[TestProviders.betaLimitsJob]?.backoff.retryAt == retryAt)

        harness.advance(by: 119)
        #expect(!harness.send(.refreshRequested(harness.newRequest())).ranJobs.contains(TestProviders.betaLimitsJob))
    }

    @Test("B-35 during a backoff, the next timer waits until retryAt")
    func timerWaitsForRetryAt() {
        var harness = ReducerHarness()
        let runs = harness.send(.launched(settings: .defaults(enabled: [.beta]), cached: [:], history: UsageHistory())).runs
        let limits = runs.first { $0.0 == TestProviders.betaLimitsJob }!
        let effects = harness.send(.taskFinished(limits.0, limits.1, .failure(.rateLimited(retryAt: ReducerHarness.start.addingTimeInterval(90))), jitter: 1))
        #expect(effects.timerDelays == [TestProviders.betaLimitsJob: 90])
    }

    @Test("B-33 without Retry-After, each 429 in a row waits 1, 2, 4… minutes, up to 60")
    func backoffDoublesUpToAnHour() {
        var outcomes = ReducerHarness.healthyOutcomes
        outcomes[TestProviders.betaLimitsJob] = .failure(.rateLimited(retryAt: nil))
        var harness = ReducerHarness.launched(finishing: outcomes)
        var waits: [TimeInterval] = [harness.state.jobs[TestProviders.betaLimitsJob]!.backoff.retryAt!.timeIntervalSince(harness.now)]
        for _ in 1...7 {
            waits.append(fireAndFinish(&harness, TestProviders.betaLimitsJob, with: .failure(.rateLimited(retryAt: nil))) ?? -1)
        }
        #expect(waits == [60, 120, 240, 480, 960, 1_920, 3_600, 3_600])
    }

    @Test("B-33 any other outcome resets the backoff", arguments: [
        Result<Part, ProviderIssue>.success(.limits(TestProviders.betaLimits)), .failure(.offline),
    ])
    func otherOutcomesResetTheBackoff(outcome: Result<Part, ProviderIssue>) {
        var outcomes = ReducerHarness.healthyOutcomes
        outcomes[TestProviders.betaLimitsJob] = .failure(.rateLimited(retryAt: nil))
        var harness = ReducerHarness.launched(finishing: outcomes)
        #expect(fireAndFinish(&harness, TestProviders.betaLimitsJob, with: outcome) == 600)
        #expect(harness.state.jobs[TestProviders.betaLimitsJob]?.backoff == RateLimitBackoff())
    }

    @Test("B-36 a timer that fired lets go of itself before its run, and the run re-arms a new one")
    func firedTimerLetsGoBeforeItsRun() throws {
        var harness = ReducerHarness.launched()
        let key = TestProviders.alphaLimitsJob
        let timer = try #require(harness.timer(of: key))
        harness.advance(by: 300)
        let effects = harness.send(.timerFired(key, timer))
        #expect(effects.ranJobs == [key])
        #expect(harness.timer(of: key) == nil)
        let (_, run) = try #require(effects.runs.first)
        let next = harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0))
        #expect(next.timerDelays[key] == 300)
        #expect(harness.timer(of: key) != timer)
    }

    @Test("B-36 a timer whose event arrives after it was replaced or cancelled is dropped")
    func lateTimerEventsAreDropped() throws {
        var harness = ReducerHarness.launched()
        let key = TestProviders.alphaLimitsJob
        let stale = try #require(harness.timer(of: key))
        // The Refresh button runs the job, which drops that timer and arms another when it finishes.
        _ = harness.finishAll(harness.send(.refreshRequested(harness.newRequest())))
        #expect(harness.timer(of: key) != stale)
        #expect(harness.send(.timerFired(key, stale)).isEmpty)
    }
}
