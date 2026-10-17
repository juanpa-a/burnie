import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// The runtime end to end: use cases in, `AppModel.state` out, over fake providers and ports, a manual clock and a
/// manual sleeper. Every wait is on a signal; should a change lose one, the time limit fails the test instead of
/// hanging the run.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct AppModelTests {
    let providers = TestProviders()
    let clock = ManualClock(now: ReducerHarness.start)
    let sleeper = ManualSleeper()
    let cache = InMemorySnapshotCache()
    let settings = InMemorySettingsStore()
    let systemEvents = FakeSystemEvents()
    let loginItem = FakeLoginItem()
    let updater = FakeUpdater()
    let urlOpener = RecordingURLOpener()
    let lifecycle = RecordingAppLifecycle()

    var environment: AppEnvironment {
        AppEnvironment(
            clock: clock,
            sleeper: sleeper,
            snapshotCache: cache,
            settingsStore: settings,
            systemEvents: systemEvents,
            loginItem: loginItem,
            updater: updater,
            urlOpener: urlOpener,
            lifecycle: lifecycle,
            providers: providers.bundles,
            jitter: { 0 }
        )
    }

    /// The app as it starts, once the first run of every job is done, so every job has its timer armed. The test keeps
    /// the model: the runtime only holds it weakly, so a dropped model hears no more events.
    func launch() async -> AppModel {
        let model = AppModel.live(environment)
        await sleeper.nextSleeps(4)
        return model
    }

    @Test("decision 43: the first state already shows the cache, before any refresh")
    func firstStateShowsTheCache() {
        let cached = RuntimeStateTests.cachedAlpha
        cache.save(cached)
        providers.alphaLimits.gate.close()
        providers.alphaActivity.gate.close()
        let model = AppModel.live(environment)
        #expect(model.state.providers.first?.state == .ready(cached))
        providers.alphaLimits.gate.open()
        providers.alphaActivity.gate.open()
    }

    @Test("B-50 first launch starts every provider, saves nothing, and starts system events and the updater")
    func firstLaunch() async {
        let model = await launch()
        #expect(model.state.settings == .defaults(enabled: [.alpha, .beta]))
        #expect(settings.saves.isEmpty)
        #expect(systemEvents.starts == 1)
        #expect(providers.watcher.starts == 1)
        #expect(providers.alphaRuns == [1, 1])
        #expect(providers.betaRuns == [1, 1])
    }

    @Test("B-19 B-42 each finished run saves the snapshot as shown, and each activity the history")
    func runsSaveTheCacheAndTheHistory() async {
        let model = await launch()
        #expect(cache.snapshot(for: .alpha) == model.state.providers.first?.state.snapshot)
        #expect(cache.savedSnapshots == 4)
        #expect(cache.savedHistories == 2)
    }

    @Test("B-38 waking up refreshes every job 3 s later, waiting through the sleeper")
    func wakeRefreshesThreeSecondsLater() async {
        let model = await launch()
        systemEvents.wake()
        #expect(await sleeper.nextSleeps(1) == [3])
        #expect(providers.alphaRuns == [1, 1])

        clock.advance(by: 3)
        sleeper.resume { $0 == 3 }
        await sleeper.nextSleeps(4)
        #expect(providers.alphaRuns == [2, 2])
        #expect(providers.betaRuns == [2, 2])
        #expect(model.state.lastUpdated == clock.now)
    }

    @Test("B-36 a timer fires its job, whose run arms the next timer, with the run left alone")
    func timerRunsItsJob() async {
        let model = await launch()
        clock.advance(by: 600)
        sleeper.resume { $0 == 600 }
        #expect(await sleeper.nextSleeps(1) == [600])
        #expect(providers.betaRuns == [2, 1])
        #expect(model.state.lastUpdated == clock.now)
    }

    @Test("B-59 the Refresh use case returns once every run it started finished, and the state spins meanwhile")
    func refreshSpinsUntilEveryRunFinishes() async {
        let model = await launch()
        providers.alphaLimits.gate.close()
        async let refreshed: Void = model.useCases.refreshUsage()
        await providers.alphaLimits.gate.waitForArrivals(2)
        await sleeper.nextSleeps(3)
        #expect(model.state.isRefreshing)

        providers.alphaLimits.gate.open()
        await refreshed
        #expect(!model.state.isRefreshing)
    }

    @Test("B-23 renewing a sign-in returns true and refreshes that provider's limits")
    func renewalRefreshesTheLimits() async {
        let model = await launch()
        #expect(await model.useCases.renewSignIn(.alpha))
        #expect(providers.renewer.runs.count == 1)
        #expect(providers.alphaRuns == [2, 1])
        #expect(providers.betaRuns == [1, 1])
    }

    @Test("B-22 a provider that can't renew answers false without running anything")
    func providerWithoutRenewalAnswersFalse() async {
        let model = await launch()
        #expect(await model.useCases.renewSignIn(.beta) == false)
        #expect(providers.renewer.runs.isEmpty)
    }

    @Test("B-37 B-51 turning a provider off and on at once applies both in order, so it ends up running")
    func quickOffAndOnApplyInOrder() async {
        let model = await launch()
        model.useCases.setProviderEnabled(.alpha, false)
        model.useCases.setProviderEnabled(.alpha, true)
        await sleeper.nextSleeps(2)
        #expect(sleeper.pending.count == 4)
        #expect(providers.alphaRuns == [2, 2])
        #expect(providers.watcher.stops == 1)
        #expect(providers.watcher.starts == 2)
        #expect(settings.saves == [.enabled([.beta]), .enabled([.alpha, .beta])])
    }

    @Test("B-31 a change the watcher reports runs the provider's activity")
    func watcherRunsTheActivity() async {
        let model = await launch()
        providers.watcher.reportChange()
        await sleeper.nextSleeps(1)
        #expect(providers.alphaRuns == [1, 2])
        #expect(model.state.providers.first?.state.snapshot?.today == .tokens(Tokens(1_800_000)))
    }

    @Test("B-58 turning launch at login on when macOS wants approval opens System Settings")
    func launchAtLoginNeedingApprovalOpensSettings() async {
        let model = await launch()
        loginItem.whenEnabled = .requiresApproval
        model.useCases.setLaunchAtLogin(true)
        #expect(loginItem.settingsOpened == 1)
        #expect(!model.state.launchAtLogin)

        loginItem.current = .enabled
        model.useCases.readLaunchAtLogin()
        #expect(model.state.launchAtLogin)
    }

    @Test("B-57 an update the updater reports shows until a check clears it, and Update opens its window")
    func updatesShowUntilCleared() async throws {
        let model = await launch()
        updater.report("0.3.0")
        try await waitUntil(model) { $0.availableUpdate == "0.3.0" }
        model.useCases.installUpdate()
        #expect(updater.installs == 1)
        updater.report(nil)
        try await waitUntil(model) { $0.availableUpdate == nil }
    }

    @Test("B-75 a dashboard link opens the provider's page, and Quit quits")
    func dashboardsAndQuit() async {
        let model = await launch()
        model.useCases.openDashboard(.alpha)
        model.useCases.quit()
        #expect(urlOpener.opened == [ProviderDescriptor.alpha.dashboard.url])
        #expect(lifecycle.quits == 1)
    }

    @Test("B-52 the heart, the switches and the providers screen save only what changed")
    func switchesSaveOnlyWhatChanged() async {
        let model = await launch()
        model.useCases.toggleFavorite(.beta)
        model.useCases.setRingShown(false)
        model.useCases.setWeekChartShown(false)
        model.useCases.setFeatureShown(.onDemand, false)
        #expect(settings.saves == [.favorite(.beta), .ringShown(false), .weekChartShown(false), .featureShown(.onDemand, false)])
        #expect(model.state.settings.favorite == .beta)
    }

    /// Callbacks from the updater arrive on the main actor later; this waits for the state they lead to.
    private func waitUntil(_ model: AppModel, _ isMet: @escaping (AppState) -> Bool) async throws {
        while !isMet(model.state) {
            try await Task.sleep(for: .zero)
        }
    }
}
