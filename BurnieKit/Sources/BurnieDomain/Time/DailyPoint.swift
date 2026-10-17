import Foundation

/// One day and its tokens.
public struct DailyPoint: Hashable, Codable, Sendable {
    public var day: LocalDay
    public var tokens: Tokens

    public init(day: LocalDay, tokens: Tokens) {
        self.day = day
        self.tokens = tokens
    }
}
