import Foundation

/// Sends requests, only to the hosts it was built for (B-60).
public protocol HTTPClient: Sendable {
    /// The response, whatever its status; throws when none arrived.
    func send(_ request: HTTPRequest) async throws(HTTPFailure) -> HTTPResponse
}
