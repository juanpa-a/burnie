import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// The circuit breaker: three unexpected answers in a row stop a job until Refresh (B-81).
extension RuntimeStateTests {
    static let refused: Result<Part, ProviderIssue> = .failure(.unexpectedResponse("HTTP 403"))

    /// Launched with beta's limits refused three times in a row: at launch, then on its next two timers.
    func refusedThreeTimes() -> ReducerHarness {
        var outcomes = ReducerHarness.healthyOutcomes
        outcomes[TestProviders.betaLimitsJob] = Self.refused
        var harness = ReducerHarness.launched(finishing: outcomes)
        _ = fireAndFinish(&harness, TestProviders.betaLimitsJob, with: Self.refused)
        _ = fireAndFinish(&harness, TestProviders.betaLimitsJob, with: Self.refused)
        return harness
    }

    @Test("B-81 three unexpected answers in a row arm no timer, and the popover, wake and network restored don't run the job")
    func aTrippedJobWaitsForRefresh() {
        var harness = refusedThreeTimes()
        let key = TestProviders.betaLimitsJob
        #expect(harness.state.jobs[key]?.breaker.isTripped == true)
        #expect(harness.timer(of: key) == nil)

        harness.advance(by: 3_600)
        #expect(!harness.send(.popoverOpened(harness.newRequest())).ranJobs.contains(key))
        #expect(!harness.send(.trigger(.wake)).ranJobs.contains(key))
        harness.send(.networkChanged(isOnline: false, jitter: 0))
        let restored = harness.send(.networkChanged(isOnline: true, jitter: 0))
        #expect(!restored.ranJobs.contains(key))
        #expect(restored.timerDelays[key] == nil)
    }

    @Test("B-81 Refresh still runs a tripped job, and a success resets its breaker and arms its timer again")
    func refreshRunsATrippedJob() throws {
        var harness = refusedThreeTimes()
        let key = TestProviders.betaLimitsJob
        let run = try #require(harness.send(.refreshRequested(harness.newRequest())).runs.first { $0.0 == key }?.1)
        let finished = harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0))
        #expect(harness.state.jobs[key]?.breaker == CircuitBreaker())
        #expect(finished.timerDelays[key] == 600)
    }

    @Test("B-81 turning the provider off and on starts its jobs with the breaker reset")
    func turningTheProviderOffAndOnResetsTheBreaker() {
        var harness = refusedThreeTimes()
        harness.send(.providerToggled(.beta, isOn: false))
        #expect(harness.send(.providerToggled(.beta, isOn: true)).ranJobs.contains(TestProviders.betaLimitsJob))
        #expect(harness.state.jobs[TestProviders.betaLimitsJob]?.breaker == CircuitBreaker())
    }
}
