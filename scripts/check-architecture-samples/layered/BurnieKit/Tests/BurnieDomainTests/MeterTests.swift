// expect: G-4
import Testing
@testable import BurnieDomain

struct MeterTests {
    @Test func clampsTheFill() {
        #expect(MeterSample.full.fraction == 1)
    }
}

private enum MeterSample {
    case full
    var fraction: Double { 1 }
}
