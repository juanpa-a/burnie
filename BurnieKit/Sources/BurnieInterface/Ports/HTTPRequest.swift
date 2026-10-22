import Foundation

/// What a provider hands the HTTP port to send.
public struct HTTPRequest: Hashable, Sendable {
    public enum Method: Hashable, Sendable {
        case get
        /// Only for endpoints that have no GET; the body is JSON.
        case post(Data)
    }

    public let method: Method
    public let url: URL
    public let headers: [String: String]

    public init(_ method: Method, url: URL, headers: [String: String]) {
        self.method = method
        self.url = url
        self.headers = headers
    }
}
