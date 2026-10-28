import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorStoredTokenTests {
    @Test("B-26 a value without the envelope is the session JWT itself")
    func plainValueIsTheJWT() throws {
        #expect(try CursorStoredToken(CursorAccessTokenTests.jwt) == .plain(jwt: CursorAccessTokenTests.jwt))
    }

    @Test("B-26 an envelope holds the safe storage value its base64 encodes")
    func envelopeHoldsTheSafeStorageValue() throws {
        #expect(try CursorStoredToken(CursorSafeStorageTests.stored) == .encrypted(CursorSafeStorageTests.encrypted))
        #expect(CursorSafeStorageTests.encrypted.starts(with: Data("v10".utf8)))
    }

    @Test("B-26 an envelope that isn't base64 is unexpected")
    func malformedEnvelopeIsUnexpected() {
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor's encrypted session isn't base64")) {
            try CursorStoredToken("cursor-safe-storage:v1:not base64!")
        }
    }
}
