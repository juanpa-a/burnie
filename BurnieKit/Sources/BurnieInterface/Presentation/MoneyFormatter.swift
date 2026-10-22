import BurnieDomain
import Foundation

/// Dollars from cents: amounts always with two decimals, limits without decimals when whole.
public struct MoneyFormatter: Sendable {
    public let locale: Locale

    public init(locale: Locale) {
        self.locale = locale
    }

    /// "$1.06", "$13.40"
    public func amount(_ cents: Cents) -> String {
        dollars(cents, fractionLength: 2)
    }

    /// "$20", "$12.50"
    public func limit(_ cents: Cents) -> String {
        dollars(cents, fractionLength: cents.amount.isMultiple(of: 100) ? 0 : 2)
    }

    private func dollars(_ cents: Cents, fractionLength: Int) -> String {
        let value = Decimal(cents.amount) / 100
        return "$" + value.formatted(.number.precision(.fractionLength(fractionLength)).locale(locale))
    }
}
