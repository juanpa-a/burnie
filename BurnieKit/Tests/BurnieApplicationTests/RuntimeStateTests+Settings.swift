import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// The user's switches: which providers are tracked, the favorite, and what each saves.
extension RuntimeStateTests {
    @Test("B-37 B-51 turning a provider off saves the key, stops its watcher, cancels its timers and keeps what it showed")
    func turningOffStopsWorkAndKeepsData() {
        var harness = ReducerHarness.launched()
        let shown = harness.state.shown[.alpha]
        let history = harness.state.history
        let effects = harness.send(.providerToggled(.alpha, isOn: false))
        #expect(effects == [
            .saveSetting(.enabled([.beta])), .stopWatcher(.alpha),
            .cancelTimer(TestProviders.alphaLimitsJob), .cancelTimer(TestProviders.alphaActivityJob),
        ])
        #expect(harness.state.shown[.alpha] == shown)
        #expect(harness.state.history == history)
        #expect(harness.state.jobs[TestProviders.alphaLimitsJob] == nil)
    }

    @Test("B-37 B-51 turning a provider on starts its watcher and runs its jobs at once")
    func turningOnResumes() {
        var harness = ReducerHarness.launched()
        harness.send(.providerToggled(.alpha, isOn: false))
        let effects = harness.send(.providerToggled(.alpha, isOn: true))
        #expect(Array(effects.prefix(2)) == [.saveSetting(.enabled([.alpha, .beta])), .startWatcher(.alpha)])
        #expect(effects.ranJobs == [TestProviders.alphaLimitsJob, TestProviders.alphaActivityJob])
    }

    @Test("a provider switch to the state it's in, or for an unknown provider, changes nothing")
    func noOpTogglesAreIgnored() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.providerToggled(.alpha, isOn: true)).isEmpty)
        #expect(harness.send(.providerToggled(ProviderID(rawValue: "gone"), isOn: true)).isEmpty)
    }

    @Test("B-52 each heart tap saves the one favorite, replacing or clearing it; a disabled provider's changes nothing")
    func heartSavesTheFavorite() {
        var harness = ReducerHarness.launched()
        var saves: [Effect] = []
        saves += harness.send(.favoriteTapped(.alpha))
        saves += harness.send(.favoriteTapped(.beta))
        saves += harness.send(.favoriteTapped(.beta))
        harness.send(.providerToggled(.alpha, isOn: false))
        saves += harness.send(.favoriteTapped(.alpha))
        #expect(saves == [.saveSetting(.favorite(.alpha)), .saveSetting(.favorite(.beta)), .saveSetting(.favorite(nil)), .saveSetting(.favorite(nil))])
        #expect(harness.state.settings.favorite == nil)
    }

    @Test("SPEC 12 each display switch saves only its own key; enabledProviders only when a provider switch changes")
    func eachSwitchSavesOnlyItsOwnKey() {
        var harness = ReducerHarness.launched()
        #expect(harness.send(.ringShownSet(false)) == [.saveSetting(.ringShown(false))])
        #expect(harness.send(.weekChartShownSet(false)) == [.saveSetting(.weekChartShown(false))])
        #expect(harness.send(.featureShownSet(.onDemand, false)) == [.saveSetting(.featureShown(.onDemand, false))])
        #expect(harness.state.settings == AppSettings(enabled: [.alpha, .beta], favorite: nil, showRing: false, showWeekChart: false, hiddenFeatures: [.onDemand]))

        #expect(harness.send(.featureShownSet(.onDemand, true)) == [.saveSetting(.featureShown(.onDemand, true))])
        #expect(harness.state.settings.hiddenFeatures.isEmpty)
    }
}
