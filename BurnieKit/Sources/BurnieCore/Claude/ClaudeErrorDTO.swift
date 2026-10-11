import Foundation

/// Anthropic API error body; only the message matters.
struct ClaudeErrorDTO: Decodable {
    struct Detail: Decodable {
        let message: String?
    }

    let error: Detail?
}
