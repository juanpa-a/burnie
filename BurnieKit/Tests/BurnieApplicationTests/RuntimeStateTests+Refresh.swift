import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// What refreshes outside the timers: the Refresh button, opening the popover, the watcher, and how long a request
/// stays open.
extension RuntimeStateTests {
    @Test("B-32 a job never runs twice at once: a trigger while it runs starts nothing")
    func singleFlight() {
        var harness = ReducerHarness()
        let launch = harness.send(.launched(settings: .defaults(enabled: [.beta]), cached: [:], history: UsageHistory()))
        #expect(launch.ranJobs == [TestProviders.betaLimitsJob, TestProviders.betaActivityJob])
        #expect(harness.send(.refreshRequested(harness.newRequest())).ranJobs.isEmpty)
        #expect(harness.send(.trigger(.wake)).ranJobs.isEmpty)
    }

    @Test("B-31 the Refresh button runs every enabled job, whatever its age")
    func refreshRunsEveryJob() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.refreshRequested(harness.newRequest())).ranJobs == Self.allJobs)
    }

    @Test("B-59 a Refresh request stays open until every run it started finishes, then hands back its result")
    func refreshRequestClosesWithItsLastRun() {
        var harness = ReducerHarness.launched()
        let request = harness.newRequest()
        let runs = harness.send(.refreshRequested(request)).runs
        #expect(harness.state.requests[request]?.runs.count == 4)

        for (key, run) in runs.dropLast() {
            #expect(!harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0)).contains(.finishRequest(request, result: true)))
        }
        let (key, run) = runs[runs.count - 1]
        #expect(harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0)).last == .finishRequest(request, result: true))
        #expect(harness.state.requests.isEmpty)
    }

    @Test("B-59 a request that starts no run closes at once")
    func requestWithoutRunsClosesAtOnce() {
        var harness = ReducerHarness()
        harness.send(.launched(settings: .defaults(enabled: []), cached: [:], history: UsageHistory()))
        let request = harness.newRequest()
        #expect(harness.send(.refreshRequested(request)) == [.finishRequest(request, result: true)])
    }

    @Test("B-39 opening the popover runs only what's stale, and a second open within 1 s runs nothing")
    func popoverOpensAreDebounced() {
        var harness = ReducerHarness.launched()
        harness.advance(by: 59.5)
        #expect(harness.send(.popoverOpened(harness.newRequest())).ranJobs.isEmpty)

        // The limits are stale now, but the last open was 0.6 s ago.
        harness.advance(by: 0.6)
        #expect(harness.send(.popoverOpened(harness.newRequest())).isEmpty)

        harness.advance(by: 0.5)
        #expect(harness.send(.popoverOpened(harness.newRequest())).ranJobs == [TestProviders.alphaLimitsJob, TestProviders.betaLimitsJob])
    }

    @Test("B-59 a popover's refresh keeps its request open while it runs (B-39)")
    func popoverRefreshOpensARequest() {
        var harness = ReducerHarness.launched()
        harness.advance(by: 61)
        let request = harness.newRequest()
        harness.send(.popoverOpened(request))
        #expect(harness.state.requests[request]?.runs.count == 2)
    }

    @Test("B-31 a change of activity runs only that provider's activity job")
    func activityChangedRunsTheActivityJob() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.activityChanged(.alpha)).ranJobs == [TestProviders.alphaActivityJob])
    }

    @Test("B-38 waking up waits 3 s, then runs every job")
    func wakeWaitsThreeSeconds() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.woke) == [.wait(3, then: .trigger(.wake))])
        #expect(harness.send(.trigger(.wake)).ranJobs == Self.allJobs)
    }
}
