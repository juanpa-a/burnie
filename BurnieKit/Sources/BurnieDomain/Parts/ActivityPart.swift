import Foundation

/// What a provider reports about its activity: tokens per local day.
public struct ActivityPart: Hashable, Sendable {
    public var tokens: [LocalDay: Tokens]

    public init(tokens: [LocalDay: Tokens]) {
        self.tokens = tokens
    }

    /// Today's usage as the header reads it: today's tokens, zero without any.
    public func usage(on today: LocalDay) -> TodayUsage {
        TodayUsage(tokens: tokens[today, default: .zero])
    }
}
