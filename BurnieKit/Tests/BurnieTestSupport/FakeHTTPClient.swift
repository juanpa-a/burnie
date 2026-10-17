import BurnieCore
import Foundation

/// `HTTPClient` that answers whatever the test says and remembers every request.
/// `lock` serializes `reply`, `routes` and `sent`, so tasks can share it.
public final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    private typealias Reply = @Sendable (URL) throws -> (Data, HTTPURLResponse)

    private let lock = NSLock()
    private var reply: Reply
    /// Replies specific to a URL, used in turn with the last one repeating; every other URL gets `reply`.
    private var routes: [URL: [Reply]] = [:]
    private var sent: [HTTPRequest] = []

    /// Every request sent so far, in order.
    public var requests: [HTTPRequest] { lock.withLock { sent } }

    public init(status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        reply = Self.reply(status: status, body: body, headers: headers)
    }

    public init(failingWith error: Error) {
        reply = { _ in throw error }
    }

    public func respond(status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        lock.withLock {
            reply = Self.reply(status: status, body: body, headers: headers)
        }
    }

    public func respond(to url: URL, status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        respond(to: url, withEach: [body], status: status, headers: headers)
    }

    /// Answers successive requests to `url` with each body in turn, like the pages of a listing.
    public func respond(to url: URL, withEach bodies: [Data], status: Int = 200, headers: [String: String] = [:]) {
        lock.withLock {
            routes[url] = bodies.map { Self.reply(status: status, body: $0, headers: headers) }
        }
    }

    private static func reply(status: Int, body: Data, headers: [String: String]) -> Reply {
        // A test's status and headers on an absolute URL always make a response.
        { url in (body, HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers)!) }
    }

    public func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let reply = lock.withLock {
            sent.append(request)
            guard let replies = routes[request.url], let next = replies.first else { return self.reply }
            if replies.count > 1 {
                routes[request.url] = Array(replies.dropFirst())
            }
            return next
        }
        return try reply(request.url)
    }
}
