import Foundation

public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse)
}
