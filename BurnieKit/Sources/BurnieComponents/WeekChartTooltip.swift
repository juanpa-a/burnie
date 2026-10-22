import BurnieDomain
import BurnieInterface
import SwiftUI

/// One day of the week chart, over its column while it's hovered: the day, then each provider's tokens and, where its
/// plan measures money and the day's spend is known, the spend (B-77, B-78).
struct WeekChartTooltip: View {
    let chart: WeekChart
    let day: LocalDay
    /// The chart's providers, in its order.
    let providers: [ProviderDescriptor]
    @Environment(\.locale) private var locale

    var body: some View {
        ChartTooltip(
            title: DayLabelFormatter(locale: locale).shortDate(for: day),
            rows: providers.map { provider in
                ChartTooltip.Row(
                    provider: provider,
                    tokens: chart.tokens(of: provider.id, on: day),
                    detail: chart.spent(of: provider.id, on: day).map { Copy.weekChartSpend(MoneyFormatter(locale: locale).amount($0)) }
                )
            }
        )
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        WeekChartTooltip(chart: PreviewValues.chart, day: PreviewValues.today, providers: [PreviewValues.northwind, PreviewValues.tailspin])
            .padding(DesignTokens.Insets.weekChart)
    }
}
#endif
