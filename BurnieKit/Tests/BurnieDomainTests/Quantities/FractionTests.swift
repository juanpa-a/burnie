import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct FractionTests {
    @Test("B-1 a fraction is clamped to 0…1 and NaN reads as 0", arguments: [
        (1.04, 1.0), (-0.2, 0.0), (0.64, 0.64), (.nan, 0.0), (.infinity, 1.0), (-.infinity, 0.0),
    ])
    func clampsToZeroThroughOne(raw: Double, expected: Double) {
        #expect(Fraction(raw).value == expected)
    }

    @Test(arguments: Gen.seeds(200))
    func everyDoubleLandsWithinZeroThroughOne(seed: UInt64) {
        var gen = Gen(seed: seed)
        #expect((0...1).contains(Fraction(gen.double()).value), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func clampingTwiceIsClampingOnce(seed: UInt64) {
        var gen = Gen(seed: seed)
        let once = Fraction(gen.double())
        #expect(Fraction(once.value) == once, "seed \(seed)")
    }

    @Test func encodesAsTheBareNumberAndClampsWhenDecoded() throws {
        #expect(String(decoding: try JSONEncoder().encode(Fraction(0.5)), as: UTF8.self) == "0.5")
        #expect(try JSONDecoder().decode(Fraction.self, from: Data("1.04".utf8)) == Fraction(1))
    }

    @Test(arguments: Gen.seeds(200))
    func roundTripsThroughJSON(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        let fraction = Fraction(gen.double())
        #expect(try JSONDecoder().decode(Fraction.self, from: JSONEncoder().encode(fraction)) == fraction, "seed \(seed)")
    }
}
