import BurnieCore
import BurnieTestSupport
import Foundation
import Testing

/// What makes the store refresh outside the timers (waking up, opening the popover, the Refresh button) and how
/// long the Refresh spinner shows.
extension UsageStoreTests {
    @Test("B-38 waking up refreshes every task 3 s later, waiting through the sleeper")
    func wakeRefreshesThreeSecondsLater() async {
        let store = await launch()
        systemEvents.wake()
        #expect(await sleeper.nextSleeps(1) == [3])
        #expect(claude.limits.calls == 1)

        clock.advance(by: 3)
        sleeper.resume { $0 == 3 }
        await sleeper.nextSleeps(4)
        #expect(claude.reads == [2, 2])
        #expect(cursor.reads == [2, 2])
        #expect(store.lastUpdated == clock.now)
    }

    @Test("B-39 a popover open within 1 s of the last one refreshes nothing, stale limits or not; a later one refreshes them")
    func popoverOpensAreDebounced() async {
        let store = await launch()
        // Short of the 60 s after which opening the popover refreshes the limits.
        clock.advance(by: 59.5)
        await store.popoverOpened()?.value
        #expect(claude.reads == [1, 1])

        // The limits are stale now, but the last open was 0.6 s ago.
        clock.advance(by: 0.6)
        let debounced = store.popoverOpened()
        #expect(debounced == nil)
        #expect(claude.reads == [1, 1])
        #expect(cursor.reads == [1, 1])

        clock.advance(by: 0.5)
        await store.popoverOpened()?.value
        #expect(claude.reads == [2, 1])
        #expect(cursor.reads == [2, 1])
    }

    @Test("B-59 the Refresh button spins until every run it started finishes")
    func refreshButtonSpinsUntilEveryRunFinishes() async {
        let store = await launch()
        claude.limits.gate.close()
        async let refreshed: Void = store.refreshAll(force: true)
        await sleeper.nextSleeps(3)
        #expect(store.isRefreshing)

        claude.limits.gate.open()
        await refreshed
        #expect(!store.isRefreshing)
    }

    @Test("B-59 the spinner stays while any refresh request is still open")
    func spinnerStaysWhileAnyRequestIsOpen() async {
        let store = await launch()
        claude.limits.gate.close()
        async let first: Void = store.refreshAll(force: true)
        await claude.limits.gate.waitForArrivals(2)

        await store.refreshAll(force: true)
        #expect(store.isRefreshing)

        claude.limits.gate.open()
        await first
        #expect(!store.isRefreshing)
    }

    @Test("B-59 a popover's refresh shows the spinner while it runs (B-39)")
    func popoverRefreshSpins() async {
        let store = await launch()
        clock.advance(by: 61)
        claude.limits.gate.close()
        store.popoverOpened()
        await claude.limits.gate.waitForArrivals(2)
        #expect(store.isRefreshing)

        claude.limits.gate.open()
    }

    @Test("B-59 a sign-in renewal spins while the provider's app renews it and its limits refresh")
    func renewalSpinsUntilItsLimitsRefresh() async throws {
        let store = await launch()
        let renewer = try #require(claude.renewer)
        renewer.gate.close()
        claude.limits.gate.close()
        async let renewed = store.renewSignIn(.claude)
        await renewer.gate.waitForArrivals(1)
        #expect(store.isRefreshing)

        renewer.gate.open()
        await claude.limits.gate.waitForArrivals(2)
        #expect(store.isRefreshing)

        claude.limits.gate.open()
        #expect(await renewed)
        #expect(!store.isRefreshing)
    }
}
