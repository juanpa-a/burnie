import Foundation

/// The last 7 days of history for the given providers, on one shared scale: the same tokens draw the same height for
/// every provider (B-43). Providers whose plan measures money also carry each day's spend (B-78), and providers with a
/// cycle their cycle total, which the legend shows (B-76, B-79).
public struct WeekChart: Hashable, Sendable {
    public static let dayCount = 7

    /// 7 consecutive local days, ending today.
    public let days: [LocalDay]
    /// In the order they were given.
    public let providers: [ProviderID]
    /// 7 values per provider, one per day, 0 for days without data.
    public let series: [ProviderID: [Tokens]]
    /// 7 values per provider with spend, one per day, nil for a day whose spend isn't known. A provider whose plan
    /// measures tokens has no entry.
    public let spent: [ProviderID: [Cents?]]
    /// The busiest day of any provider, which draws at full height; zero when every day is.
    public let peak: Tokens
    /// The cycle total of each provider that has one. A provider without a cycle, or whose history has no day of it,
    /// has no entry.
    public let cycleTotals: [ProviderID: Tokens]

    /// `spent` holds each day's spend of the providers whose plan measures money (`ActivityPart.spend(in:)`), and
    /// `cycleStarts` the local day each provider's cycle starts on (`MeterSet.cycle`); a provider that isn't in
    /// `providers` is left out of both.
    public static func make(
        history: UsageHistory,
        providers: [ProviderID],
        today: LocalDay,
        spent: [ProviderID: [LocalDay: Cents]] = [:],
        cycleStarts: [ProviderID: LocalDay] = [:]
    ) -> WeekChart {
        let days = Array(today.advanced(by: 1 - dayCount)...today)
        let series = providers.map { provider in
            (provider, history.points(for: provider, endingAt: today, count: dayCount).map(\.tokens))
        }
        let spentSeries = providers.compactMap { provider in
            spent[provider].map { daily in (provider, days.map { daily[$0] }) }
        }
        let cycleTotals = providers.compactMap { provider -> (ProviderID, Tokens)? in
            guard let start = cycleStarts[provider],
                  let total = history.cycleTotal(for: provider, startingOn: start, today: today) else { return nil }
            return (provider, total)
        }
        return WeekChart(
            days: days,
            providers: providers,
            series: Dictionary(series, uniquingKeysWith: { first, _ in first }),
            spent: Dictionary(spentSeries, uniquingKeysWith: { first, _ in first }),
            peak: series.flatMap(\.1).max() ?? .zero,
            cycleTotals: Dictionary(cycleTotals, uniquingKeysWith: { first, _ in first })
        )
    }

    /// The provider's tokens on `day`; zero for a day or a provider the chart doesn't have.
    public func tokens(of provider: ProviderID, on day: LocalDay) -> Tokens {
        value(in: series[provider], on: day) ?? .zero
    }

    /// The provider's spend on `day`; nil when it isn't known, the plan measures tokens, or the chart doesn't have the
    /// day (B-78).
    public func spent(of provider: ProviderID, on day: LocalDay) -> Cents? {
        value(in: spent[provider], on: day) ?? nil
    }

    /// The value of `day` in a series that has one per day of `days`.
    private func value<Value>(in daily: [Value]?, on day: LocalDay) -> Value? {
        guard let daily, let index = days.firstIndex(of: day), daily.indices.contains(index) else { return nil }
        return daily[index]
    }
}
