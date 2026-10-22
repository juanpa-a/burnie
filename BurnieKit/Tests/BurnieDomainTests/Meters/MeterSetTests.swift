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

    @Test(arguments: Gen.seeds(200))
    func theCycleIsALongestPeriod(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meters = gen.meterSet()
        let periods = meters.all.compactMap(\.period)
        #expect((meters.cycle == nil) == periods.isEmpty, "seed \(seed)")
        #expect(meters.cycle.map { cycle in periods.contains(cycle) && periods.allSatisfy { $0.duration <= cycle.duration } } ?? true, "seed \(seed)")
    }

    @Test("B-79 a provider's cycle is its longest period, whichever meter has it")
    func theCycleIsTheLongestPeriod() {
        let day = DateInterval(start: .iso("2026-10-10T06:00:00Z"), duration: 86_400)
        let month = DateInterval(start: .iso("2026-10-03T00:00:00Z"), duration: 31 * 86_400)
        let daily = Meter(id: .daily, fill: Fraction(0.6), value: .percent(60), caption: .resetsIn(day.end), period: day)
        let monthly = Meter(id: .monthly, fill: Fraction(0.2), value: .percent(20), caption: .cycleEnds(month.end), period: month)
        let extra = Meter(id: .extra, fill: .zero, value: .money(used: .zero, limit: nil), caption: .onDemandIdle)
        #expect(MeterSet(primary: daily, others: [monthly, extra]).cycle == month)
        #expect(MeterSet(primary: extra).cycle == nil)
    }

    @Test("B-53 the first meter in display order is the primary one")
    func theFirstMeterIsPrimary() {
        let daily = Meter(id: .daily, fill: Fraction(0.6), value: .percent(60), caption: .noActiveSession)
        let monthly = Meter(id: .monthly, fill: Fraction(0.2), value: .percent(20), caption: .noActiveSession)
        #expect(MeterSet([daily, monthly]) == MeterSet(primary: daily, others: [monthly]))
    }
}
