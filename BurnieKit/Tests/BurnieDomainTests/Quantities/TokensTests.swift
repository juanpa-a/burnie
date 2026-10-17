import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct TokensTests {
    @Test(arguments: Gen.seeds(200))
    func additionIsAssociative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (a, b, c) = (gen.tokens(), gen.tokens(), gen.tokens())
        #expect((a + b) + c == a + (b + c), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func additionIsCommutative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (a, b) = (gen.tokens(), gen.tokens())
        #expect(a + b == b + a, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func zeroIsTheIdentity(seed: UInt64) {
        var gen = Gen(seed: seed)
        let a = gen.tokens()
        #expect(a + .zero == a, "seed \(seed)")
        #expect(a - .zero == a, "seed \(seed)")
    }

    @Test func additionSaturatesInsteadOfTrapping() {
        #expect(Tokens(.max) + Tokens(1) == Tokens(.max))
        #expect(Tokens(.min) - Tokens(1) == Tokens(.min))
    }

    @Test func encodesAsTheBareNumber() throws {
        #expect(String(decoding: try JSONEncoder().encode(Tokens(1_250_000)), as: UTF8.self) == "1250000")
        #expect(try JSONDecoder().decode(Tokens.self, from: Data("1250000".utf8)) == Tokens(1_250_000))
    }
}
