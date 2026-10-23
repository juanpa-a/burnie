import BurnieDomain
import Foundation

/// The header's text for today's usage: "25M tokens today".
public struct TodayUsageFormatter: Sendable {
    private let tokens: TokenCountFormatter

    public init(locale: Locale) {
        tokens = TokenCountFormatter(locale: locale)
    }

    public func string(for usage: TodayUsage) -> String {
        "\(tokens.string(from: usage.tokens)) tokens today"
    }
}
