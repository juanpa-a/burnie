import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ProviderStateTests {
    @Test("B-18 a total failure over a shown snapshot shows it with the issue on top")
    func failureOverASnapshotKeepsIt() {
        var gen = Gen(seed: 1)
        let shown = gen.snapshot()
        var withIssue = shown
        withIssue.issue = .signInExpired
        #expect(ProviderState.failing(.signInExpired, previous: shown) == .ready(withIssue))
    }

    @Test("B-18 a total failure without a snapshot shows the failure alone")
    func failureWithoutASnapshotIsTheFailure() {
        #expect(ProviderState.failing(.notFound, previous: nil) == .failed(.notFound))
    }

    @Test(arguments: Gen.seeds(200))
    func failingNeverLosesTheContent(seed: UInt64) {
        var gen = Gen(seed: seed)
        let shown = gen.snapshot()
        let issue = gen.issue()
        let failed = ProviderState.failing(issue, previous: shown)
        #expect(failed.snapshot?.content == shown.content, "seed \(seed)")
        #expect(failed.snapshot?.issue == issue, "seed \(seed)")
    }

    @Test("B-40 hiding features only touches a ready state")
    func hidingTouchesOnlyReadyStates() {
        #expect(ProviderState.loading.hiding([.onDemand]) == .loading)
        #expect(ProviderState.failed(.offline).hiding([.onDemand]) == .failed(.offline))
    }
}
