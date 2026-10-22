import Foundation

/// The last 7 days of history for the given providers, on one shared scale: the same tokens draw the same height for
/// every provider (B-43).
public struct WeekChart: Hashable, Sendable {
    public static let dayCount = 7

    /// 7 consecutive local days, ending today.
    public let days: [LocalDay]
    /// In the order they were given.
    public let providers: [ProviderID]
    /// 7 values per provider, one per day, 0 for days without data.
    public let series: [ProviderID: [Tokens]]
    /// The busiest day of any provider, which draws at full height; zero when every day is.
    public let peak: Tokens

    public static func make(history: UsageHistory, providers: [ProviderID], today: LocalDay) -> WeekChart {
        let series = providers.map { provider in
            (provider, history.points(for: provider, endingAt: today, count: dayCount).map(\.tokens))
        }
        return WeekChart(
            days: Array(today.advanced(by: 1 - dayCount)...today),
            providers: providers,
            series: Dictionary(series, uniquingKeysWith: { first, _ in first }),
            peak: series.flatMap(\.1).max() ?? .zero
        )
    }
}
