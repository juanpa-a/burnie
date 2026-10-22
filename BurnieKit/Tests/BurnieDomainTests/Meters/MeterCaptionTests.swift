import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct MeterCaptionTests {
    static let reset = Date(timeIntervalSince1970: 1_791_669_600)

    @Test(arguments: [
        (MeterCaption.resetsIn(reset), #"{"resetsIn":1791669600}"#),
        (.resetsAt(reset), #"{"resetsAt":1791669600}"#),
        (.cycleEnds(reset), #"{"cycleEnds":1791669600}"#),
        (.noActiveSession, #"{"noActiveSession":{}}"#),
        (.onDemandIdle, #"{"onDemandIdle":{}}"#),
    ])
    func encodesAsAnObjectKeyedByItsCase(caption: MeterCaption, json: String) throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(caption), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(MeterCaption.self, from: Data(json.utf8)) == caption)
    }
}
