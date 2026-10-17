import BurnieCore
import BurnieTestSupport
import Foundation
import Testing

/// The user's switches: which providers are tracked, the favorite, and what they save.
extension UsageStoreTests {
    @Test("B-37 turning a provider off and on at once applies both in order, so it ends up running")
    func quickOffAndOnApplyInOrder() async {
        let store = await launch()
        store.setEnabled(.claude, false)
        store.setEnabled(.claude, true)

        await sleeper.nextSleeps(2)
        // Cursor's two timers and Claude's new ones: Claude's old timers went with turning it off.
        #expect(sleeper.pending.count == 4)
        #expect(claude.reads == [2, 2])
    }

    @Test("B-51 turning a provider off keeps its cache and history and stops its watcher and timers")
    func turningOffKeepsDataAndStopsWork() async throws {
        let store = await launch()
        let shown = store.states[.claude]
        let history = store.history[.claude]

        store.setEnabled(.claude, false)
        await sleeper.waitUntilPending(2)

        #expect(claude.watcher.stops == 1)
        #expect(sleeper.pending.allSatisfy { $0 == CursorWaits.activity || CursorWaits.limits.contains($0) })
        #expect(store.states[.claude] == shown)
        #expect(store.history[.claude] == history)
        #expect(try cachedSnapshot(.claude).map(ProviderState.ready) == shown)
        #expect(try cachedHistory()?.points(for: .claude, endingAt: Self.today) == Self.week([0, 0, 0, 0, 400_000, 0, 1_800_000]))
        #expect(enabled.value == [.cursor])
    }

    @Test("B-51 turning a provider back on restarts its watcher and refreshes it")
    func turningBackOnResumes() async {
        let store = await launch()
        store.setEnabled(.claude, false)
        store.setEnabled(.claude, true)
        await sleeper.nextSleeps(2)
        #expect(claude.watcher.starts == 2)
        #expect(claude.reads == [2, 2])

        claude.watcher.reportChange()
        await sleeper.nextSleeps(1)
        #expect(claude.reads == [2, 3])
        #expect(store.enabled == Set(ProviderID.allCases))
    }

    @Test("B-52 each heart tap saves the one favorite, replacing or clearing it; a disabled provider's changes nothing")
    func heartSavesTheFavorite() async {
        let store = await launch()
        store.toggleFavorite(.claude)
        store.toggleFavorite(.cursor)
        store.toggleFavorite(.cursor)
        store.setEnabled(.claude, false)
        store.toggleFavorite(.claude)
        #expect(store.favorite == nil)
        #expect(favorite.saves == [.claude, .cursor, nil, nil])
    }

    @Test("B-74 without an effective favorite the ring switch keeps its stored value")
    func ringSwitchKeepsItsValueWithoutAFavorite() async {
        favorite.value = .claude
        let store = await launch()
        store.toggleFavorite(.claude)
        #expect(store.effectiveFavorite == nil)
        #expect(store.showRing)
        #expect(store.ring == .hidden)

        store.toggleFavorite(.claude)
        #expect(store.showRing)
        #expect(store.ring == .visible(.claude, fraction: 0.64))
        #expect(showRing.saves.isEmpty)
        #expect(showRing.value)
    }

    @Test("enabledProviders is saved only when a provider switch changes; every other switch saves only its own")
    func eachSwitchSavesOnlyItsOwnSetting() async {
        let store = await launch()
        store.setShowRing(false)
        store.setShowWeekChart(false)
        store.setShowOnDemand(false)
        store.toggleFavorite(.cursor)
        store.setEnabled(.claude, true)
        #expect(enabled.saves.isEmpty)
        #expect(showRing.saves == [false])
        #expect(showWeekChart.saves == [false])
        #expect(showOnDemand.saves == [false])
        #expect(favorite.saves == [.cursor])

        store.setEnabled(.cursor, false)
        #expect(enabled.saves == [[.claude]])
    }
}
