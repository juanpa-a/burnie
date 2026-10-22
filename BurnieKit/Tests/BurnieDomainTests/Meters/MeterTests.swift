import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct MeterTests {
    static let session = DateInterval(start: .iso("2026-10-10T10:00:00Z"), duration: 5 * 3_600)

    func meter(fill: Double = 0.2, period: DateInterval?) -> Meter {
        Meter(id: .daily, fill: Fraction(fill), value: .percent(20), caption: .noActiveSession, period: period)
    }

    @Test("B-1 a meter's fill is clamped to 0…1 and NaN reads as 0", arguments: [
        (1.04, 1.0), (-0.2, 0.0), (0.64, 0.64), (.nan, 0.0), (.infinity, 1.0),
    ])
    func clampsTheFill(raw: Double, expected: Double) {
        #expect(meter(fill: raw, period: nil).fill.value == expected)
    }

    @Test("B-2 a percent meter clamps the API's 0–100 value and rounds the shown percent", arguments: [
        (64.4, 64), (64.5, 65), (35.25, 35), (104.4, 100), (-3.0, 0), (.nan, 0),
    ])
    func percentMeterClampsAndRounds(used: Double, shown: Int) {
        #expect(Meter.percent(.daily, used: used, caption: .noActiveSession).value == .percent(shown))
    }

    @Test("B-2 a percent meter's fill is the clamped percent over 100")
    func percentMeterFill() {
        #expect(Meter.percent(.daily, used: 64, caption: .noActiveSession).fill == Fraction(0.64))
        #expect(Meter.percent(.daily, used: 104, caption: .noActiveSession).fill == Fraction(1))
    }

    @Test("B-3 the pace is how far through the period now is", arguments: [
        ("2026-10-10T10:00:00Z", 0.0), ("2026-10-10T12:30:00Z", 0.5), ("2026-10-10T15:00:00Z", 1.0),
    ])
    func paceIsHowFarThroughThePeriodNowIs(now: String, expected: Double) {
        #expect(meter(period: Self.session).elapsedFraction(at: .iso(now)) == Fraction(expected))
    }

    @Test("B-3 no pace while now is outside the period", arguments: ["2026-10-10T09:59:00Z", "2026-10-10T15:01:00Z"])
    func noPaceOutsideThePeriod(now: String) {
        #expect(meter(period: Self.session).elapsedFraction(at: .iso(now)) == nil)
    }

    @Test("B-3 no pace without a period")
    func noPaceWithoutAPeriod() {
        #expect(meter(period: nil).elapsedFraction(at: .iso("2026-10-10T12:30:00Z")) == nil)
    }

    @Test("B-3 no pace with a zero-duration period")
    func noPaceForAnInstantPeriod() {
        let instant = DateInterval(start: .iso("2026-10-10T12:30:00Z"), duration: 0)
        #expect(meter(period: instant).elapsedFraction(at: instant.start) == nil)
    }

    @Test("B-5 the fill past the pace is over pace; behind the pace none is")
    func overPaceIsTheFillPastThePace() {
        let halfway = Date.iso("2026-10-10T12:30:00Z")
        #expect(meter(fill: 0.7, period: Self.session).overPace(at: halfway).value == 0.7 - 0.5)
        #expect(meter(fill: 0.3, period: Self.session).overPace(at: halfway) == .zero)
    }

    @Test("B-5 without a pace tick, all of the fill is on pace")
    func withoutAPaceNothingIsOverPace() {
        #expect(meter(fill: 0.9, period: nil).overPace(at: .iso("2026-10-10T12:30:00Z")) == .zero)
    }

    @Test func encodesItsPropertiesByName() throws {
        let meter = Meter(id: .daily, fill: Fraction(0.5), value: .percent(50), caption: .noActiveSession)
        let json = String(decoding: try JSONEncoder.persistence.encode(meter), as: UTF8.self)
        #expect(json == #"{"caption":{"noActiveSession":{}},"fill":0.5,"id":"daily","value":{"percent":50}}"#)
    }

    @Test(arguments: Gen.seeds(200))
    func roundTripsThroughJSON(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        let meter = gen.meter()
        #expect(try JSONDecoder.persistence.decode(Meter.self, from: JSONEncoder.persistence.encode(meter)) == meter, "seed \(seed)")
    }
}
