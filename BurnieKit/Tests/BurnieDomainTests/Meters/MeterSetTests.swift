import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct MeterSetTests {
    @Test(arguments: Gen.seeds(200))
    func allStartsWithThePrimaryMeter(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meters = gen.meterSet()
        #expect(meters.all.first == meters.primary, "seed \(seed)")
        #expect(meters.all.count == meters.others.count + 1, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func rebuildingFromAllGivesTheSameSet(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meters = gen.meterSet()
        #expect(MeterSet(meters.all) == meters, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func onlyNoMetersMakeNoSet(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meters = (0..<gen.int(in: 0...3)).map { _ in gen.meter() }
        #expect((MeterSet(meters) == nil) == meters.isEmpty, "seed \(seed)")
    }

    @Test("B-53 the first meter in display order is the primary one")
    func theFirstMeterIsPrimary() {
        let daily = Meter(id: .daily, fill: Fraction(0.6), value: .percent(60), caption: .noActiveSession)
        let monthly = Meter(id: .monthly, fill: Fraction(0.2), value: .percent(20), caption: .noActiveSession)
        #expect(MeterSet([daily, monthly]) == MeterSet(primary: daily, others: [monthly]))
    }
}
