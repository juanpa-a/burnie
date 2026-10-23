import Foundation

/// What a provider hands the HTTP port to send: a GET, the only method Burnie sends, so it only ever reads.
public struct HTTPRequest: Hashable, Sendable {
    public let url: URL
    public let headers: [String: String]

    public init(url: URL, headers: [String: String]) {
        self.url = url
        self.headers = headers
    }
}
