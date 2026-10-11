import Testing
@testable import BurnieCore

struct MeterTests {
    @Test(arguments: [(1.04, 1.0), (-0.2, 0.0), (0.64, 0.64), (.nan, 0.0), (.infinity, 1.0)])
    func clampsFractionToZeroThroughOne(raw: Double, expected: Double) {
        let meter = Meter(id: .session, fraction: raw, value: .percent(0), caption: .noActiveSession)
        #expect(meter.fraction == expected)
    }
}
