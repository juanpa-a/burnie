import Foundation

/// What a provider reports about its activity: tokens per local day and, where it can add it up exactly, the money
/// spent.
public struct ActivityPart: Hashable, Sendable {
    public var tokens: [LocalDay: Tokens]
    /// Only the days the provider added up exactly; empty when it can't tell.
    public var spent: [LocalDay: Cents]

    public init(tokens: [LocalDay: Tokens], spent: [LocalDay: Cents] = [:]) {
        self.tokens = tokens
        self.spent = spent
    }

    /// Today's usage as the header reads it: money when the plan measures money and today's spend is known, tokens
    /// otherwise (B-7).
    public func usage(on today: LocalDay, in unit: UsageUnit) -> TodayUsage {
        if unit == .money, let cents = spent[today] {
            return .money(cents)
        }
        return .tokens(tokens[today, default: .zero])
    }

    /// Every day's spend as the week chart shows it: the days added up when the plan measures money, nil when it
    /// measures tokens (B-78).
    public func spend(in unit: UsageUnit) -> [LocalDay: Cents]? {
        unit == .money ? spent : nil
    }
}
