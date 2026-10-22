import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

/// Renewing an expired sign-in through the provider's own app.
extension RuntimeStateTests {
    @Test("B-22 only an enabled provider that can renew asks its app; the rest answer false at once")
    func onlyAProviderThatCanRenewAsks() {
        var harness = ReducerHarness.launched()
        let alpha = harness.newRequest()
        #expect(harness.send(.renewRequested(.alpha, alpha)) == [.renewSignIn(.alpha, alpha)])
        #expect(harness.state.requests[alpha]?.isRenewing == true)

        let beta = harness.newRequest()
        #expect(harness.send(.renewRequested(.beta, beta)) == [.finishRequest(beta, result: false)])

        harness.send(.providerToggled(.alpha, isOn: false))
        let off = harness.newRequest()
        #expect(harness.send(.renewRequested(.alpha, off)) == [.finishRequest(off, result: false)])
    }

    @Test("B-23 B-59 a renewal that worked refreshes that provider's limits, however fresh, before its request closes")
    func successfulRenewalRefreshesTheLimits() throws {
        var harness = ReducerHarness.launched()
        let request = harness.newRequest()
        harness.send(.renewRequested(.alpha, request))
        let effects = harness.send(.renewFinished(.alpha, succeeded: true, request))
        #expect(effects.ranJobs == [TestProviders.alphaLimitsJob])
        #expect(harness.state.requests[request]?.isRenewing == false)

        let (key, run) = try #require(effects.runs.first)
        #expect(harness.send(.taskFinished(key, run, ReducerHarness.healthyOutcomes[key]!, jitter: 0)).last == .finishRequest(request, result: true))
    }

    @Test("B-23 a renewal the provider's app couldn't finish answers false and refreshes nothing (B-22)")
    func failedRenewalRefreshesNothing() {
        var harness = ReducerHarness.launched()
        let request = harness.newRequest()
        harness.send(.renewRequested(.alpha, request))
        #expect(harness.send(.renewFinished(.alpha, succeeded: false, request)) == [.finishRequest(request, result: false)])
    }
}
