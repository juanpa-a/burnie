import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct MeterTests {
    static let session = DateInterval(start: .iso("2026-10-10T10:00:00Z"), duration: 5 * 3_600)

    func meter(period: DateInterval?) -> Meter {
        Meter(id: .session, fraction: 0.2, value: .percent(20), caption: .noActiveSession, period: period)
    }

    @Test(arguments: [(1.04, 1.0), (-0.2, 0.0), (0.64, 0.64), (.nan, 0.0), (.infinity, 1.0)])
    func clampsFractionToZeroThroughOne(raw: Double, expected: Double) {
        let meter = Meter(id: .session, fraction: raw, value: .percent(0), caption: .noActiveSession)
        #expect(meter.fraction == expected)
    }

    @Test(arguments: Gen.seeds(200))
    func fractionIsWithinZeroThroughOneForEveryDouble(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meter = Meter(id: .session, fraction: gen.double(), value: .percent(0), caption: .noActiveSession)
        #expect((0...1).contains(meter.fraction), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func fractionClampIsIdempotent(seed: UInt64) {
        var gen = Gen(seed: seed)
        let meter = gen.meter()
        let clampedAgain = Meter(id: meter.id, fraction: meter.fraction, value: meter.value, caption: meter.caption, period: meter.period)
        #expect(clampedAgain == meter, "seed \(seed)")
    }

    @Test(arguments: [("2026-10-10T10:00:00Z", 0.0), ("2026-10-10T12:30:00Z", 0.5), ("2026-10-10T15:00:00Z", 1.0)])
    func elapsedFractionIsHowFarThroughThePeriodNowIs(now: String, expected: Double) {
        #expect(meter(period: Self.session).elapsedFraction(at: .iso(now)) == expected)
    }

    @Test(arguments: ["2026-10-10T09:59:00Z", "2026-10-10T15:01:00Z"])
    func noElapsedFractionOutsideThePeriod(now: String) {
        #expect(meter(period: Self.session).elapsedFraction(at: .iso(now)) == nil)
    }

    @Test func noElapsedFractionWithoutAPeriod() {
        #expect(meter(period: nil).elapsedFraction(at: .iso("2026-10-10T12:30:00Z")) == nil)
    }

    @Test func meterCachedBeforePeriodsStillDecodes() throws {
        let json = #"{"id":"session","fraction":0.2,"value":{"percent":{"_0":20}},"caption":{"noActiveSession":{}}}"#
        #expect(try JSONDecoder().decode(Meter.self, from: Data(json.utf8)) == meter(period: nil))
    }
}
