import Foundation
import Testing
@testable import BurnieDomain

struct SpecificIssueTests {
    @Test func encodesAsTheBareCode() throws {
        let issue = SpecificIssue(code: "missingScope")
        #expect(String(decoding: try JSONEncoder().encode(issue), as: UTF8.self) == #""missingScope""#)
        #expect(try JSONDecoder().decode(SpecificIssue.self, from: Data(#""missingScope""#.utf8)) == issue)
    }
}
