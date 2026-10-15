import Foundation
import os
import BurnieCore

/// `HTTPClient` on an ephemeral session: no cookies or disk cache, no redirects followed,
/// and only to allowed hosts, which are checked before any header is sent.
public final class URLSessionHTTPClient: HTTPClient {
    public enum Failure: Error, Equatable {
        case hostNotAllowed(String?)
        case notHTTP
    }

    private let allowedHosts: Set<String>
    private let session: URLSession
    private let logger: Logger

    public init(allowedHosts: Set<String>, logger: Logger, timeout: TimeInterval = 10) {
        self.allowedHosts = allowedHosts
        self.logger = logger
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
    }

    public func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let url = request.url
        guard url.scheme == "https", let host = url.host(), allowedHosts.contains(host) else {
            throw Failure.hostNotAllowed(url.host())
        }
        let started = ContinuousClock.now
        let (body, response) = try await session.data(for: Self.urlRequest(for: request), delegate: RedirectRefusal())
        guard let response = response as? HTTPURLResponse else { throw Failure.notHTTP }
        let elapsed = (ContinuousClock.now - started).formatted(.units(allowed: [.milliseconds]))
        logger.info("\(request.method.name, privacy: .public) \(url.path, privacy: .public) → \(response.statusCode) in \(elapsed, privacy: .public)")
        return (body, response)
    }

    /// What goes on the wire; separate so tests can check it without the network.
    static func urlRequest(for request: HTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.name
        if case .post(let body) = request.method {
            urlRequest.httpBody = body
        }
        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }
}

private extension HTTPRequest.Method {
    var name: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        }
    }
}

/// A redirect (for example, to Cursor's login) arrives as a 3xx response instead of being followed
/// with the credentials to another host.
private final class RedirectRefusal: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        nil
    }
}
