import BurnieDomain
import Foundation

/// What VoiceOver reads for the week chart, which can't hover a day: the cycle totals, then every day with its spend
/// where it's known (B-76, B-77, B-78).
public enum WeekChartAccessibilityValue {
    /// "This cycle: Claude 48M tokens, Cursor 61M tokens; Sat: Claude 1.8M tokens, Cursor 2.6M tokens ($4.12); …",
    /// with `providers` being the chart's, in its order. A provider without a cycle total is left out of the first
    /// part, and without any the part is too.
    public static func text(for chart: WeekChart, providers: [ProviderDescriptor], locale: Locale) -> String {
        let tokens = TokenCountFormatter(locale: locale)
        let money = MoneyFormatter(locale: locale)
        let dayNames = DayLabelFormatter(locale: locale)
        let cycleTotals = providers.compactMap { provider in
            chart.cycleTotals[provider.id].map { Copy.providerUsage(provider: provider.shortName, tokens: tokens.string(from: $0)) }
        }
        let cycle = cycleTotals.isEmpty ? [] : ["\(Copy.thisCycle): \(cycleTotals.joined(separator: ", "))"]
        let days = chart.days.map { day in
            let usage = providers.map { provider in
                Copy.providerUsage(
                    provider: provider.shortName,
                    tokens: tokens.string(from: chart.tokens(of: provider.id, on: day)),
                    spent: chart.spent(of: provider.id, on: day).map(money.amount)
                )
            }
            return "\(dayNames.shortName(for: day)): \(usage.joined(separator: ", "))"
        }
        return (cycle + days).joined(separator: "; ")
    }
}
