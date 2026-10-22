import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct TodayUsageTests {
    @Test(arguments: [(TodayUsage.tokens(Tokens(1_250_000)), #"{"tokens":1250000}"#), (.money(Cents(1_240)), #"{"money":1240}"#)])
    func encodesAsAnObjectKeyedByItsCase(usage: TodayUsage, json: String) throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(usage), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(TodayUsage.self, from: Data(json.utf8)) == usage)
    }
}
