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

    public func get(_ url: URL, headers: [String: String]) async throws -> (Data, HTTPURLResponse) {
        guard url.scheme == "https", let host = url.host(), allowedHosts.contains(host) else {
            throw Failure.hostNotAllowed(url.host())
        }
        var request = URLRequest(url: url)
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        let started = ContinuousClock.now
        let (body, response) = try await session.data(for: request, delegate: RedirectRefusal())
        guard let response = response as? HTTPURLResponse else { throw Failure.notHTTP }
        let elapsed = (ContinuousClock.now - started).formatted(.units(allowed: [.milliseconds]))
        logger.info("GET \(url.path, privacy: .public) → \(response.statusCode) in \(elapsed, privacy: .public)")
        return (body, response)
    }
}

/// A redirect (for example, to Cursor's login) arrives as a 3xx response instead of being followed
/// with the credentials to another host.
private final class RedirectRefusal: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        nil
    }
}
