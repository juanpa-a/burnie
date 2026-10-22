import Foundation

/// What the HTTP port got back.
public struct HTTPResponse: Hashable, Sendable {
    public let status: Int
    public let headers: [String: String]
    public let mimeType: String?
    public let body: Data

    public init(status: Int, headers: [String: String] = [:], mimeType: String? = nil, body: Data = Data()) {
        self.status = status
        self.headers = headers
        self.mimeType = mimeType
        self.body = body
    }

    /// The value of the header `name`, whatever its case (`Retry-After`, B-24).
    public func header(_ name: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}
