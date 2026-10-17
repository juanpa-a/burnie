import BurnieInterface
import Foundation

/// An `HTTPClient` that answers whatever the test says and remembers every request.
/// `lock` serializes `reply`, `routes` and `sent`, so tasks can share it.
public final class FakeHTTPClient: HTTPClient, @unchecked Sendable {
    private typealias Reply = Result<HTTPResponse, HTTPFailure>

    private let lock = NSLock()
    private var reply: Reply
    /// Replies specific to a URL, used in turn with the last one repeating; every other URL gets `reply`.
    private var routes: [URL: [Reply]] = [:]
    private var sent: [HTTPRequest] = []

    /// Every request sent so far, in order.
    public var requests: [HTTPRequest] { lock.withLock { sent } }

    public init(status: Int = 200, body: Data = Data(), headers: [String: String] = [:], mimeType: String? = nil) {
        reply = .success(HTTPResponse(status: status, headers: headers, mimeType: mimeType, body: body))
    }

    public init(failingWith failure: HTTPFailure) {
        reply = .failure(failure)
    }

    public func respond(status: Int = 200, body: Data = Data(), headers: [String: String] = [:], mimeType: String? = nil) {
        lock.withLock {
            reply = .success(HTTPResponse(status: status, headers: headers, mimeType: mimeType, body: body))
        }
    }

    public func fail(with failure: HTTPFailure) {
        lock.withLock { reply = .failure(failure) }
    }

    public func respond(to url: URL, status: Int = 200, body: Data = Data(), headers: [String: String] = [:]) {
        respond(to: url, withEach: [body], status: status, headers: headers)
    }

    /// Answers successive requests to `url` with each body in turn, like the pages of a listing.
    public func respond(to url: URL, withEach bodies: [Data], status: Int = 200, headers: [String: String] = [:]) {
        lock.withLock {
            routes[url] = bodies.map { .success(HTTPResponse(status: status, headers: headers, body: $0)) }
        }
    }

    public func send(_ request: HTTPRequest) async throws(HTTPFailure) -> HTTPResponse {
        let reply = lock.withLock {
            sent.append(request)
            guard let replies = routes[request.url], let next = replies.first else { return self.reply }
            if replies.count > 1 {
                routes[request.url] = Array(replies.dropFirst())
            }
            return next
        }
        return try reply.get()
    }
}
