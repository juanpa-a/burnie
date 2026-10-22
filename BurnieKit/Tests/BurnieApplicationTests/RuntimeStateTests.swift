import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// The reducer, event by event. Every step checks the invariant of SPEC 7.3 (`ReducerHarness`).
struct RuntimeStateTests {
    static let allJobs = [TestProviders.alphaLimitsJob, TestProviders.alphaActivityJob, TestProviders.betaLimitsJob, TestProviders.betaActivityJob]

    @Test("B-37 launch starts the system events, the updater, each enabled provider's watcher, and a run of every job")
    func launchStartsEverything() {
        var harness = ReducerHarness()
        let effects = harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [:], history: UsageHistory()))
        #expect(Array(effects.prefix(4)) == [.startSystemEvents, .startUpdater, .startWatcher(.alpha), .startWatcher(.beta)])
        #expect(effects.ranJobs == Self.allJobs)
    }

    @Test("B-50 first launch shows every provider loading, enabled, with nothing yet to show")
    func firstLaunchShowsLoading() {
        var harness = ReducerHarness()
        harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [:], history: UsageHistory()))
        #expect(harness.state.shown == [.alpha: .loading, .beta: .loading])
        #expect(harness.state.settings == .defaults(enabled: [.alpha, .beta]))
    }

    @Test("decision 43: launch shows each provider's cached snapshot, else loading")
    func launchShowsTheCache() {
        var gen = Gen(seed: 7)
        var cached = gen.snapshot()
        cached.provider = .beta
        var harness = ReducerHarness()
        harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [.beta: cached], history: UsageHistory()))
        #expect(harness.state.shown == [.alpha: .loading, .beta: .ready(cached)])
    }

    @Test("SPEC 12 an enabled id the registry doesn't know is ignored, and dropped on the next save of the key")
    func unknownEnabledIDsAreDropped() {
        var harness = ReducerHarness()
        let saved = AppSettings(enabled: [.alpha, ProviderID(rawValue: "gone")], favorite: nil, showRing: true, showWeekChart: true, hiddenFeatures: [])
        let effects = harness.send(.launched(settings: saved, cached: [:], history: UsageHistory()))
        #expect(harness.state.settings.enabled == [.alpha])
        #expect(effects.ranJobs == [TestProviders.alphaLimitsJob, TestProviders.alphaActivityJob])
        #expect(harness.send(.providerToggled(.beta, isOn: true)).first == .saveSetting(.enabled([.alpha, .beta])))
    }

    @Test("B-34 the runtime starts online, so the first runs include the jobs that need the network")
    func startsOnline() {
        var harness = ReducerHarness()
        #expect(harness.state.isOnline)
        #expect(harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [:], history: UsageHistory())).ranJobs == Self.allJobs)
    }

    @Test("a disabled provider has no jobs and no watcher")
    func disabledProvidersDoNothing() {
        var harness = ReducerHarness()
        let effects = harness.send(.launched(settings: .defaults(enabled: [.beta]), cached: [:], history: UsageHistory()))
        #expect(!effects.contains(.startWatcher(.alpha)))
        #expect(Set(harness.state.jobs.keys) == [TestProviders.betaLimitsJob, TestProviders.betaActivityJob])
    }
}
