import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct MeterValueTests {
    @Test(arguments: [
        (MeterValue.percent(64), #"{"percent":64}"#),
        (.money(used: Cents(1_340), limit: Cents(2_000)), #"{"money":{"limit":2000,"used":1340}}"#),
        (.money(used: Cents(0), limit: nil), #"{"money":{"used":0}}"#),
    ])
    func encodesAsAnObjectKeyedByItsCase(value: MeterValue, json: String) throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(value), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(MeterValue.self, from: Data(json.utf8)) == value)
    }

    @Test(arguments: [#"{"percent":{"_0":64}}"#, #"{}"#, #"{"percent":64,"money":{"used":0}}"#])
    func anyOtherShapeDoesNotDecode(json: String) {
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(MeterValue.self, from: Data(json.utf8)) }
    }
}
