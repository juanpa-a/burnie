import Foundation

/// Today's usage as a provider's header shows it: "25M tokens today". Encodes as `{"tokens": 1250000}` (SPEC section
/// 12).
public struct TodayUsage: Hashable, Codable, Sendable {
    public var tokens: Tokens

    public init(tokens: Tokens) {
        self.tokens = tokens
    }
}
