import BurnieDomain
import Foundation

/// What VoiceOver reads for the week chart, which can't hover: the week totals, the cycle totals, then every day with
/// its spend where it's known (B-77, B-78, B-80).
public enum WeekChartAccessibilityValue {
    /// "Last 7 days: Claude 12M tokens, Cursor 13M tokens; This cycle: Claude 48M tokens since Oct 16, Cursor 61M tokens
    /// since Oct 3; Sat: Claude 1.8M tokens, Cursor 2.6M tokens ($4.12); …", with `providers` being the chart's, in its
    /// order. Without any cycle total, the cycle part is left out.
    public static func text(for chart: WeekChart, providers: [ProviderDescriptor], locale: Locale) -> String {
        let tokens = TokenCountFormatter(locale: locale)
        let money = MoneyFormatter(locale: locale)
        let dayNames = DayLabelFormatter(locale: locale)
        let totals = providers.map { provider in
            Copy.providerUsage(provider: provider.shortName, tokens: tokens.string(from: chart.total(for: provider.id)))
        }
        let cycleTotals = providers.compactMap { provider in
            chart.cycleTotals[provider.id].map { total in
                Copy.cycleUsage(provider: provider.shortName, tokens: tokens.string(from: total.tokens), since: dayNames.monthDay(for: total.since))
            }
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
        return (["\(Copy.lastSevenDays): \(totals.joined(separator: ", "))"] + cycle + days).joined(separator: "; ")
    }
}
