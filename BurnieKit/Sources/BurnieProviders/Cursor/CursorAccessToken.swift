import BurnieDomain
import Foundation

/// The Cursor app's session JWT. Only the payload is decoded; the signature isn't verified.
struct CursorAccessToken {
    let jwt: String
    /// What follows the last `|` in `sub` (the whole `sub` if there's no `|`).
    let userID: String
    let expiresAt: Date

    private struct Payload: Decodable {
        let sub: String
        let exp: Double
    }

    /// A malformed JWT counts as an expired session: the fix for the user is to sign in to Cursor again.
    init(jwt: String) throws(ProviderIssue) {
        let segments = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3, let payloadData = Self.base64URLDecoded(segments[1]),
              let payload = try? JSONDecoder().decode(Payload.self, from: payloadData) else {
            throw .signInExpired
        }
        self.jwt = jwt
        userID = payload.sub.split(separator: "|").last.map(String.init) ?? payload.sub
        expiresAt = Date(timeIntervalSince1970: payload.exp)
    }

    /// The cursor.com dashboard cookie: `userId::jwt`, with `::` encoded.
    var sessionCookie: String {
        "WorkosCursorSessionToken=\(userID)%3A%3A\(jwt)"
    }

    private static func base64URLDecoded(_ segment: Substring) -> Data? {
        var base64 = segment.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}
