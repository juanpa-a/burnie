import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct PartTests {
    @Test func aPartKnowsItsKind() {
        var gen = Gen(seed: 0)
        #expect(Part.limits(gen.limitsPart()).kind == .limits)
        #expect(Part.activity(gen.activityPart()).kind == .activity)
    }
}
