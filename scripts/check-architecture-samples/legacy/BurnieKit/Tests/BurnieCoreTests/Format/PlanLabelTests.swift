// expect: G-4
import Testing
@testable import BurnieCore

struct PlanLabelTests {
    @Test func namesThePlan() {
        #expect(PlanLabelFixture.max.name == "MAX")
    }
}

private enum PlanLabelFixture {
    case max
    var name: String { "MAX" }
}
