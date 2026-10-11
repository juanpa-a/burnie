import Foundation

/// Dollars from cents: amounts always with two decimals, limits without decimals when whole.
public struct MoneyFormatter: Sendable {
    public let locale: Locale

    public init(locale: Locale) {
        self.locale = locale
    }

    /// "$1.06", "$13.40"
    public func amount(cents: Int) -> String {
        dollars(cents, fractionLength: 2)
    }

    /// "$20", "$12.50"
    public func limit(cents: Int) -> String {
        dollars(cents, fractionLength: cents.isMultiple(of: 100) ? 0 : 2)
    }

    private func dollars(_ cents: Int, fractionLength: Int) -> String {
        let value = Decimal(cents) / 100
        return "$" + value.formatted(.number.precision(.fractionLength(fractionLength)).locale(locale))
    }
}
