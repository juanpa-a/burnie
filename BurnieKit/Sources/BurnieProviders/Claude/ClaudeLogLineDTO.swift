import Foundation

/// A line of the JSONL files in `~/.claude/projects`. Only the keys that count tokens.
struct ClaudeLogLineDTO: Decodable {
    struct Usage: Decodable {
        let inputTokens: Int?
        let outputTokens: Int?
        let cacheCreationInputTokens: Int?
        let cacheReadInputTokens: Int?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
        }
    }

    struct Message: Decodable {
        let id: String?
        let model: String?
        let usage: Usage?
    }

    let type: String?
    /// ISO 8601 UTC with milliseconds.
    let timestamp: String?
    let requestId: String?
    let message: Message?
}
