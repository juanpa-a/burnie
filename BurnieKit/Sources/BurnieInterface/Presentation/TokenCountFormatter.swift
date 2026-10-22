import BurnieDomain
import Foundation

/// Abbreviated token counts, rounded down and without ".0": 980, 9.6K, 640K, 1.8M, 12M.
public struct TokenCountFormatter: Sendable {
    public let locale: Locale

    public init(locale: Locale) {
        self.locale = locale
    }

    public func string(from tokens: Tokens) -> String {
        let count = tokens.count
        return switch count {
        case ..<1_000: whole(count)
        case ..<10_000: oneDecimal(count, unit: 1_000) + "K"
        case ..<1_000_000: whole(count / 1_000) + "K"
        case ..<10_000_000: oneDecimal(count, unit: 1_000_000) + "M"
        default: whole(count / 1_000_000) + "M"
        }
    }

    private func whole(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    /// Truncates to tenths with integer math so 9,999 is "9.9K" and not "10K".
    private func oneDecimal(_ count: Int, unit: Int) -> String {
        let tenths = Decimal(count / (unit / 10)) / 10
        return tenths.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }
}
