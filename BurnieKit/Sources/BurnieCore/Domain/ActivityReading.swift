import Foundation

/// What an `ActivitySource` delivers: tokens per local day and, where the source can add it up, the money spent.
public struct ActivityReading: Sendable, Equatable {
    public var tokens: [LocalDay: Int]
    /// Cents per local day; only the days the source added up exactly, empty if it can't tell.
    public var spentCents: [LocalDay: Int]

    public init(tokens: [LocalDay: Int], spentCents: [LocalDay: Int] = [:]) {
        self.tokens = tokens
        self.spentCents = spentCents
    }
}
