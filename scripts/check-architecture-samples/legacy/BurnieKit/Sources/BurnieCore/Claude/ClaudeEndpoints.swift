// expect: G-9
import Foundation

/// Where the usage API lives. Only the first URL says why its force unwrap can't fail.
public enum ClaudeEndpoints {
    // A literal URL, so it always parses.
    static let profile = URL(string: "https://example.com/api/profile")!
    static let usage = URL(string: "https://example.com/api/usage")!
}
