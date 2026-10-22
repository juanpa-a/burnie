import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct CentsTests {
    @Test(arguments: Gen.seeds(200))
    func additionIsAssociative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (a, b, c) = (gen.cents(), gen.cents(), gen.cents())
        #expect((a + b) + c == a + (b + c), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func additionIsCommutative(seed: UInt64) {
        var gen = Gen(seed: seed)
        let (a, b) = (gen.cents(), gen.cents())
        #expect(a + b == b + a, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func zeroIsTheIdentity(seed: UInt64) {
        var gen = Gen(seed: seed)
        let a = gen.cents()
        #expect(a + .zero == a, "seed \(seed)")
        #expect(a - .zero == a, "seed \(seed)")
    }

    @Test func additionSaturatesInsteadOfTrapping() {
        #expect(Cents(.max) + Cents(1) == Cents(.max))
        #expect(Cents(.min) - Cents(1) == Cents(.min))
    }

    @Test func encodesAsTheBareNumber() throws {
        #expect(String(decoding: try JSONEncoder().encode(Cents(1_240)), as: UTF8.self) == "1240")
        #expect(try JSONDecoder().decode(Cents.self, from: Data("1240".utf8)) == Cents(1_240))
    }
}
