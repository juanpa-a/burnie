import Foundation
import Testing
@testable import BurnieInterface

struct HTTPResponseTests {
    @Test("B-24 a header is found whatever the case it arrived in", arguments: ["Retry-After", "retry-after", "RETRY-AFTER"])
    func headersIgnoreCase(name: String) {
        let response = HTTPResponse(status: 429, headers: ["retry-After": "90"])
        #expect(response.header(name) == "90")
    }

    @Test func aMissingHeaderIsNil() {
        #expect(HTTPResponse(status: 200).header("Retry-After") == nil)
    }
}
