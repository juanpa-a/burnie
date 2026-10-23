import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct TodayUsageTests {
    @Test func encodesItsTokensUnderTheirName() throws {
        let usage = TodayUsage(tokens: Tokens(1_250_000))
        let json = #"{"tokens":1250000}"#
        #expect(String(decoding: try JSONEncoder.persistence.encode(usage), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(TodayUsage.self, from: Data(json.utf8)) == usage)
    }

    @Test func moneySavedBeforeZeroFiveDoesNotDecode() {
        #expect(throws: DecodingError.self) { try JSONDecoder.persistence.decode(TodayUsage.self, from: Data(#"{"money":1240}"#.utf8)) }
    }
}
