import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// Going offline and back online.
extension RuntimeStateTests {
    @Test("B-34 offline skips the jobs that need the network; alpha's activity, which doesn't, still runs")
    func offlineSkipsNetworkJobs() {
        var harness = ReducerHarness.launched()
        harness.send(.networkChanged(isOnline: false, jitter: 0))
        #expect(harness.send(.refreshRequested(harness.newRequest())).ranJobs == [TestProviders.alphaActivityJob])
    }

    @Test("B-35 a timer that fires offline runs nothing and arms nothing; it waits for the network")
    func offlineTimerRunsNothing() throws {
        var harness = ReducerHarness.launched()
        harness.send(.networkChanged(isOnline: false, jitter: 0))
        let key = TestProviders.betaLimitsJob
        let timer = try #require(harness.timer(of: key))
        harness.advance(by: 630)
        #expect(harness.send(.timerFired(key, timer)).isEmpty)
        #expect(harness.state.jobs[key]?.timer == nil)
    }

    @Test("B-35 B-38 back online, a job older than its interval runs, and a younger one left without a timer arms it")
    func networkRestoredRunsOrArms() throws {
        var harness = ReducerHarness.launched()
        harness.send(.networkChanged(isOnline: false, jitter: 0))
        let limits = TestProviders.betaLimitsJob
        harness.advance(by: 630)
        harness.send(.timerFired(limits, try #require(harness.timer(of: limits))))

        // Past beta's 10 min limits, short of its 30 min activity, which keeps its timer.
        let effects = harness.send(.networkChanged(isOnline: true, jitter: 0))
        #expect(effects.ranJobs == [TestProviders.alphaLimitsJob, TestProviders.alphaActivityJob, limits])
        #expect(effects.timerDelays.isEmpty)
    }

    @Test("decision 47: back online too soon to run, a job the offline timer left idle arms its timer again")
    func networkRestoredArmsIdleJobs() throws {
        var harness = ReducerHarness.launched()
        let limits = TestProviders.betaLimitsJob
        _ = harness.finishAll(harness.send(.refreshRequested(harness.newRequest())))
        harness.send(.networkChanged(isOnline: false, jitter: 0))
        // The timer fires early, as it can when the clock moved: offline, the job can't run and is left idle.
        harness.advance(by: 300)
        harness.send(.timerFired(limits, try #require(harness.timer(of: limits))))

        let effects = harness.send(.networkChanged(isOnline: true, jitter: 0))
        #expect(!effects.ranJobs.contains(limits))
        #expect(effects.timerDelays[limits] == 600)
    }

    @Test("B-38 a network report while already online runs nothing")
    func onlineWhileOnlineRunsNothing() {
        var harness = ReducerHarness.launched()
        harness.advance(by: 4_000)
        #expect(harness.send(.networkChanged(isOnline: true, jitter: 0)).isEmpty)
    }
}
