import Foundation

/// A title and a URL, for the footer's dashboard item.
public struct DashboardLink: Hashable, Sendable {
    public let title: String
    public let url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}
