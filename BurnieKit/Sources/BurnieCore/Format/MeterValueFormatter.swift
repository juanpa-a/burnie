import Foundation

/// The value to the right of a meter: the bold part ("64%", "$13.40") and, for money, the limit (" / $20").
public struct MeterValueFormatter: Sendable {
    private let money: MoneyFormatter

    public init(locale: Locale) {
        money = MoneyFormatter(locale: locale)
    }

    public func parts(for value: MeterValue) -> (amount: String, limit: String?) {
        switch value {
        case .percent(let percent):
            ("\(percent)%", nil)
        case .money(let usedCents, let limitCents):
            (money.amount(cents: usedCents), " / " + (limitCents.map(money.limit(cents:)) ?? "No limit"))
        }
    }
}
