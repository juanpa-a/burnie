import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct MeterIDTests {
    @Test func encodesAsTheBareString() throws {
        #expect(String(decoding: try JSONEncoder().encode(MeterID.daily), as: UTF8.self) == #""daily""#)
        #expect(try JSONDecoder().decode(MeterID.self, from: Data(#""daily""#.utf8)) == .daily)
    }
}
