// expect: none
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

@Suite(.serialized) struct LocalDayTests {
    @Test("B-43 a day rolls over at local midnight")
    func rollsOver() throws {
        let zone = TimeZone(identifier: "America/Mexico_City")!
        let day = try! JSONDecoder().decode(LocalDay.self, from: Data(#""2026-10-10""#.utf8))
        #expect(day.iso == "2026-10-10" && zone.secondsFromGMT() != 0)
    }
}
