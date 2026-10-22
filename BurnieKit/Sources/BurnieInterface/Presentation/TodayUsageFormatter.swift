import BurnieDomain
import Foundation

/// The header's text for today's usage: "25M tokens today" or "$12.40 today".
public struct TodayUsageFormatter: Sendable {
    private let tokens: TokenCountFormatter
    private let money: MoneyFormatter

    public init(locale: Locale) {
        tokens = TokenCountFormatter(locale: locale)
        money = MoneyFormatter(locale: locale)
    }

    public func string(for usage: TodayUsage) -> String {
        switch usage {
        case .tokens(let count): "\(tokens.string(from: count)) tokens today"
        case .money(let cents): "\(money.amount(cents)) today"
        }
    }
}
