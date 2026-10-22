import Foundation
import Testing
@testable import BurnieDomain

struct PlanNameTests {
    @Test func encodesAsTheBareString() throws {
        let plan = PlanName(rawValue: "PRO+")
        #expect(String(decoding: try JSONEncoder().encode(plan), as: UTF8.self) == #""PRO+""#)
        #expect(try JSONDecoder().decode(PlanName.self, from: Data(#""PRO+""#.utf8)) == plan)
    }
}
