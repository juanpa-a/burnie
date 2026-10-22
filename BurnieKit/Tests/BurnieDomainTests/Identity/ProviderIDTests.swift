import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ProviderIDTests {
    @Test func encodesAsTheBareString() throws {
        #expect(String(decoding: try JSONEncoder().encode(ProviderID.alpha), as: UTF8.self) == #""alpha""#)
        #expect(try JSONDecoder().decode(ProviderID.self, from: Data(#""alpha""#.utf8)) == .alpha)
    }

    @Test func keysAJSONObject() throws {
        let values: [ProviderID: Int] = [.alpha: 1]
        let json = String(decoding: try JSONEncoder().encode(values), as: UTF8.self)
        #expect(json == #"{"alpha":1}"#)
        #expect(try JSONDecoder().decode([ProviderID: Int].self, from: Data(json.utf8)) == values)
    }
}
