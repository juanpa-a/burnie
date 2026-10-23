import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct LatestTests {
    @Test(arguments: Gen.seeds(200))
    func aSuccessBecomesTheLastSuccess(seed: UInt64) {
        var gen = Gen(seed: seed)
        let latest = gen.latest { $0.tokens() }
        let (value, at) = (gen.tokens(), gen.date())
        #expect(latest.recording(.success(value), at: at).lastSuccess == Stamped(value, at: at), "seed \(seed)")
        #expect(latest.recording(.success(value), at: at).issue == nil, "seed \(seed)")
    }

    @Test("a failure never loses the last success", arguments: Gen.seeds(200))
    func aFailureKeepsTheLastSuccess(seed: UInt64) {
        var gen = Gen(seed: seed)
        let latest = gen.latest { $0.tokens() }
        let issue = gen.issue()
        let failed = latest.recording(.failure(issue), at: gen.date())
        #expect(failed.lastSuccess == latest.lastSuccess, "seed \(seed)")
        #expect(failed.issue == issue, "seed \(seed)")
    }

    @Test func theFirstFailureHasNoLastSuccess() {
        let failed = Latest<Tokens>(.failure(.offline), at: .iso("2026-10-10T20:00:00Z"))
        #expect(failed.lastSuccess == nil)
        #expect(failed.issue == .offline)
    }
}
