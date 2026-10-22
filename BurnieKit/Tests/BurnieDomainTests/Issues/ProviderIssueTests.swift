import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ProviderIssueTests {
    @Test(arguments: [
        (ProviderIssue.notFound, #"{"notFound":{}}"#),
        (.signInExpired, #"{"signInExpired":{}}"#),
        (.rateLimited(retryAt: Date(timeIntervalSince1970: 1_791_662_700)), #"{"rateLimited":{"retryAt":1791662700}}"#),
        (.rateLimited(retryAt: nil), #"{"rateLimited":{}}"#),
        (.offline, #"{"offline":{}}"#),
        (.unexpectedResponse("HTTP 500"), #"{"unexpectedResponse":"HTTP 500"}"#),
        (.specific(SpecificIssue(code: "missingScope")), #"{"specific":"missingScope"}"#),
    ])
    func encodesAsAnObjectKeyedByItsCase(issue: ProviderIssue, json: String) throws {
        #expect(String(decoding: try JSONEncoder.persistence.encode(issue), as: UTF8.self) == json)
        #expect(try JSONDecoder.persistence.decode(ProviderIssue.self, from: Data(json.utf8)) == issue)
    }

    @Test(arguments: Gen.seeds(200))
    func roundTripsThroughJSON(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        let issue = gen.issue()
        #expect(try JSONDecoder.persistence.decode(ProviderIssue.self, from: JSONEncoder.persistence.encode(issue)) == issue, "seed \(seed)")
    }
}
