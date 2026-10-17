// expect: G-8
import Foundation

/// Sends one request to an allowed host.
public protocol HTTPClient: Sendable {
    // TODO: add a timeout parameter.
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
