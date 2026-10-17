// expect: G-9
import BurnieInterface
import Foundation

/// Fetches the usage windows from a URL that doesn't say why it parses.
struct ClaudeUsageFetcher {
    static let url = URL(string: "https://example.com/api/oauth/usage")!
}
