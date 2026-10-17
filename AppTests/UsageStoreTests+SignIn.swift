import BurnieCore
import LegacyTestSupport
import Foundation
import Testing

/// Renewing an expired sign-in through the provider's own app.
extension UsageStoreTests {
    @Test("B-22 only a provider with a renewer can renew its sign-in")
    func onlyARenewerCanRenew() async {
        let store = await launch()
        #expect(store.canRenewSignIn(.claude))
        #expect(!store.canRenewSignIn(.cursor))
        #expect(await store.renewSignIn(.cursor) == false)
    }

    @Test("B-23 a successful renewal refreshes that provider's limits, however fresh they are")
    func successfulRenewalRefreshesTheLimits() async {
        let store = await launch()
        #expect(await store.renewSignIn(.claude))
        #expect(claude.reads == [2, 1])
        #expect(cursor.reads == [1, 1])
    }

    @Test("B-23 a renewal the provider's app couldn't finish returns false and refreshes nothing (B-22)")
    func failedRenewalRefreshesNothing() async {
        claude.renewer?.set(succeeds: false)
        let store = await launch()
        #expect(await store.renewSignIn(.claude) == false)
        #expect(claude.renewer?.calls == 1)
        #expect(claude.limits.calls == 1)
    }
}
