import BurnieInterface
import Foundation

/// `HTTPClient` on an ephemeral session: no cookies or disk cache, no redirects followed, a timeout, and only to the
/// allowed hosts, checked before any header is sent (B-60, B-70, X-7).
public final class URLSessionHTTPClient: HTTPClient {
    private let allowedHosts: Set<String>
    private let session: URLSession
    private let log: any DiagnosticsLog

    public init(allowedHosts: Set<String>, log: any DiagnosticsLog, timeout: TimeInterval = 10) {
        self.allowedHosts = allowedHosts
        self.log = log
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
    }

    /// A URL loading error (no network, a timeout) is `offline`; anything else is `other`, named by its type only, so
    /// nothing from the request reaches it (B-24, B-64).
    public func send(_ request: HTTPRequest) async throws(HTTPFailure) -> HTTPResponse {
        let url = request.url
        guard url.scheme == "https", let host = url.host(), allowedHosts.contains(host) else {
            throw .other("Host not allowed")
        }
        let started = ContinuousClock.now
        let body: Data
        let response: URLResponse
        do {
            (body, response) = try await session.data(for: Self.urlRequest(for: request), delegate: RedirectRefusal())
        } catch is URLError {
            throw .offline
        } catch {
            throw .other(String(describing: type(of: error)))
        }
        guard let response = response as? HTTPURLResponse else { throw .other("Not an HTTP response") }
        let elapsed = (ContinuousClock.now - started) / .seconds(1)
        log.record("http", [.status(response.statusCode), .seconds("elapsed", elapsed)])
        return HTTPResponse(status: response.statusCode, headers: Self.headers(of: response), mimeType: response.mimeType, body: body)
    }

    /// What goes on the wire; separate so tests can check it without the network.
    static func urlRequest(for request: HTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        switch request.method {
        case .get:
            urlRequest.httpMethod = "GET"
        case .post(let body):
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = body
        }
        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }

    private static func headers(of response: HTTPURLResponse) -> [String: String] {
        response.allHeaderFields.reduce(into: [:]) { headers, field in
            if let name = field.key as? String, let value = field.value as? String {
                headers[name] = value
            }
        }
    }

    /// A redirect (for example, to Cursor's login) arrives as a 3xx response instead of being followed with the
    /// credentials to another host.
    private final class RedirectRefusal: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
            nil
        }
    }
}
