import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageUnitTests {
    @Test(arguments: [(UsageUnit.tokens, #"{"tokens":{}}"#), (.money, #"{"money":{}}"#)])
    func encodesAsAnObjectKeyedByItsCase(unit: UsageUnit, json: String) throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(unit), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(UsageUnit.self, from: Data(json.utf8)) == unit)
    }
}
