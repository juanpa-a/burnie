import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

struct AppStateDeriveTests {
    @Test("every provider gets a panel, in registry order, with its descriptor, capabilities and effective favorite")
    func panelsFollowTheRegistry() {
        var harness = ReducerHarness.launched()
        harness.send(.providerToggled(.alpha, isOn: false))
        let panels = AppState.derive(from: harness.state).providers
        #expect(panels.map(\.id) == [.alpha, .beta])
        #expect(panels.map(\.isEnabled) == [false, true])
        #expect(panels.map(\.isFavorite) == [false, true])
        #expect(panels.map(\.renewalFailedCopy) == ["Alpha couldn't renew.", nil])
        #expect(panels.map(\.sourceLocation) == ["~/.alpha", nil])
    }

    @Test("B-53 the ring follows the effective favorite's primary meter")
    func ringFollowsTheFavorite() {
        var harness = ReducerHarness.launched()
        #expect(AppState.derive(from: harness.state).ring == .hidden)
        harness.send(.favoriteTapped(.alpha))
        #expect(AppState.derive(from: harness.state).ring == .visible(.alpha, percent: 64))
    }

    @Test("B-74 without an effective favorite the ring hides and its switch keeps its stored value")
    func ringSwitchKeepsItsValueWithoutAFavorite() {
        var harness = ReducerHarness.launched()
        harness.send(.favoriteTapped(.alpha))
        harness.send(.favoriteTapped(.alpha))
        let state = AppState.derive(from: harness.state)
        #expect(state.ring == .hidden)
        #expect(state.settings.showRing)
        #expect(state.providers.allSatisfy { !$0.isFavorite })
    }

    @Test("B-55 the header's age is the most recent data among the enabled providers, nil before any")
    func lastUpdatedIsTheNewestEnabledSnapshot() {
        var harness = ReducerHarness()
        harness.send(.launched(settings: .defaults(enabled: [.alpha, .beta]), cached: [:], history: UsageHistory()))
        #expect(AppState.derive(from: harness.state).lastUpdated == nil)

        harness = ReducerHarness.launched()
        #expect(AppState.derive(from: harness.state).lastUpdated == ReducerHarness.start)
    }

    @Test("B-40 with on-demand hidden, panels drop the feature but its switch stays")
    func hiddenOnDemandKeepsItsSwitch() throws {
        var harness = ReducerHarness.launched()
        harness.send(.featureShownSet(.onDemand, false))
        let state = AppState.derive(from: harness.state)
        let beta = try #require(state.providers.first { $0.id == .beta })
        #expect(beta.state.snapshot?.features.onDemand == nil)
        #expect(harness.shown(.beta)?.features.onDemand == TestProviders.onDemand)
        #expect(state.visibleToggles == [.onDemand])
    }

    @Test("B-40 the on-demand switch shows only while an enabled provider's snapshot has on-demand")
    func onDemandSwitchFollowsEnabledSnapshots() {
        var harness = ReducerHarness.launched()
        harness.send(.providerToggled(.beta, isOn: false))
        #expect(AppState.derive(from: harness.state).visibleToggles.isEmpty)
        harness.send(.providerToggled(.beta, isOn: true))
        #expect(AppState.derive(from: harness.state).visibleToggles == [.onDemand])
    }

    @Test("B-43 the week chart reads the 7 days ending today for the enabled providers, in registry order")
    func weekChartReadsTheEnabledProviders() throws {
        var harness = ReducerHarness.launched()
        harness.send(.providerToggled(.alpha, isOn: false))
        let chart = try #require(AppState.derive(from: harness.state).weekChart)
        #expect(chart.providers == [.beta])
        #expect(chart.days.last == TestProviders.today)
        #expect(chart.series[.beta]?.map(\.count) == [0, 0, 0, 0, 400_000, 0, 1_800_000])
    }

    @Test("B-43 the week chart rolls over with the first event after midnight")
    func weekChartRollsOverAtMidnight() throws {
        var harness = ReducerHarness.launched()
        // 23:59 in Mexico City, then the first event after midnight.
        harness.advance(by: 9 * 3_600 + 59 * 60)
        harness.send(.trigger(.timer))
        #expect(try #require(AppState.derive(from: harness.state).weekChart).days.last == TestProviders.today)
        harness.advance(by: 120)
        harness.send(.trigger(.timer))
        #expect(try #require(AppState.derive(from: harness.state).weekChart).days.last == TestProviders.today.advanced(by: 1))
    }

    @Test("B-79 a cycle total counts from the local day the shown snapshot's cycle starts on, in the latest event's time zone")
    func cycleTotalsStartOnTheCyclesLocalDay() throws {
        // 03:00 GMT on the 3rd is still the 2nd in Mexico City.
        let cycle = DateInterval(start: .iso("2026-10-03T03:00:00Z"), duration: 31 * 86_400)
        let meters = MeterSet(primary: Meter(id: .budget, fill: Fraction(0.37), value: .percent(37), caption: .cycleEnds(cycle.end), period: cycle))
        var outcomes = ReducerHarness.healthyOutcomes
        outcomes[TestProviders.betaLimitsJob] = .success(.limits(LimitsPart(plan: PlanName(rawValue: "PRO"), meters: meters)))
        var history = UsageHistory()
        history.record([.day("2026-10-02"): Tokens(50_000)], for: .beta, today: .day("2026-10-02"))

        var harness = ReducerHarness.launched(history: history, finishing: outcomes)
        let chart = try #require(AppState.derive(from: harness.state).weekChart)
        // From the 2nd: its 50K, the 8th's 400K and today's 1.8M.
        #expect(chart.cycleTotals == [.beta: Tokens(2_250_000)])

        harness.timeZone = .gmt
        harness.send(.trigger(.timer))
        let inGMT = try #require(AppState.derive(from: harness.state).weekChart)
        // From the 3rd, without the 2nd's 50K.
        #expect(inGMT.cycleTotals == [.beta: Tokens(2_200_000)])
    }

    @Test("the week chart is gone with its switch off or with every provider off")
    func weekChartNeedsItsSwitchAndAProvider() {
        var harness = ReducerHarness.launched()
        harness.send(.weekChartShownSet(false))
        #expect(AppState.derive(from: harness.state).weekChart == nil)
        harness.send(.weekChartShownSet(true))
        harness.send(.providerToggled(.alpha, isOn: false))
        harness.send(.providerToggled(.beta, isOn: false))
        #expect(AppState.derive(from: harness.state).weekChart == nil)
    }

    @Test("B-59 the state is refreshing while any request is open")
    func refreshingFollowsTheRequests() {
        var harness = ReducerHarness.launched()
        harness.send(.refreshRequested(harness.newRequest()))
        #expect(AppState.derive(from: harness.state).isRefreshing)
    }
}
