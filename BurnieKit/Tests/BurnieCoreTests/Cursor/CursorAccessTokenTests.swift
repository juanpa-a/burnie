import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct CursorAccessTokenTests {
    static let jwt = Fixture.text("cursor-jwt.txt").trimmingCharacters(in: .whitespacesAndNewlines)

    @Test func readsUserAndExpiryFromThePayload() throws {
        let token = try CursorAccessToken(jwt: Self.jwt)
        #expect(token.userID == "user_01TESTUSER00000000000000000")
        #expect(token.expiresAt == Date(timeIntervalSince1970: 1_795_000_000))
    }

    @Test func buildsTheDashboardCookie() throws {
        let cookie = try CursorAccessToken(jwt: Self.jwt).sessionCookie
        #expect(cookie == "WorkosCursorSessionToken=user_01TESTUSER00000000000000000%3A%3A\(Self.jwt)")
    }

    @Test func usesTheWholeSubjectWithoutAProviderPrefix() throws {
        #expect(try CursorAccessToken(jwt: unsignedJWT(payload: #"{"sub":"user_01PLAIN","exp":1795000000}"#)).userID == "user_01PLAIN")
    }

    @Test(arguments: ["", "not-a-jwt", "a.b", "a.!!!.c", "a.e30.c", unsignedJWT(payload: #"{"sub":"x"}"#)])
    func malformedTokensCountAsExpiredSessions(jwt: String) {
        #expect(throws: ProviderIssue.signInExpired) { try CursorAccessToken(jwt: jwt) }
    }
}

private func unsignedJWT(payload: String) -> String {
    let encoded = Data(payload.utf8).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    return "e30.\(encoded).c2ln"
}
