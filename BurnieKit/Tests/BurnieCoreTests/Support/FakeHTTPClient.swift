import Foundation
@testable import BurnieCore

/// `HTTPClient` that answers whatever the test says and remembers every request.
final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    struct Request: Equatable {
        let url: URL
        let headers: [String: String]
    }

    private typealias Reply = @Sendable (URL) throws -> (Data, HTTPURLResponse)

    private let lock = NSLock()
    private var reply: Reply
    /// Replies specific to a URL; every other URL gets `reply`.
    private var routes: [URL: Reply] = [:]
    private(set) var requests: [Request] = []

    init(status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        reply = Self.reply(status: status, body: body, headers: headers)
    }

    init(failingWith error: Error) {
        reply = { _ in throw error }
    }

    func respond(status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        lock.withLock {
            reply = Self.reply(status: status, body: body, headers: headers)
        }
    }

    func respond(to url: URL, status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        lock.withLock {
            routes[url] = Self.reply(status: status, body: body, headers: headers)
        }
    }

    private static func reply(status: Int, body: Data, headers: [String: String]) -> Reply {
        { url in (body, HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers)!) }
    }

    func get(_ url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        let reply = lock.withLock {
            requests.append(Request(url: url, headers: headers))
            return routes[url] ?? self.reply
        }
        return try reply(url)
    }
}
