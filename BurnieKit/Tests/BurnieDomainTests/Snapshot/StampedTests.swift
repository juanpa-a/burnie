import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct StampedTests {
    @Test(arguments: Gen.seeds(200))
    func mappingTheIdentityChangesNothing(seed: UInt64) {
        var gen = Gen(seed: seed)
        let stamped = gen.stamped { $0.tokens() }
        #expect(stamped.map { $0 } == stamped, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func mappingTwiceIsMappingTheComposition(seed: UInt64) {
        var gen = Gen(seed: seed)
        let stamped = gen.stamped { $0.tokens() }
        let double = { (tokens: Tokens) in tokens + tokens }
        let usage = { (tokens: Tokens) in TodayUsage(tokens: tokens) }
        #expect(stamped.map(double).map(usage) == stamped.map { usage(double($0)) }, "seed \(seed)")
    }

    @Test func encodesTheValueAndItsMoment() throws {
        let stamped = Stamped(Tokens(5), at: Date(timeIntervalSince1970: 1_791_662_100))
        #expect(String(decoding: try JSONEncoder.persistence.encode(stamped), as: UTF8.self) == #"{"at":1791662100,"value":5}"#)
    }
}
