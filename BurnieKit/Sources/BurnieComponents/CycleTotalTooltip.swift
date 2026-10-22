import BurnieDomain
import BurnieInterface
import SwiftUI

/// The cycle totals, under the week chart's legend while it's hovered: each provider's tokens over its cycle and the
/// day they count from; a provider without a cycle total is left out (B-80).
struct CycleTotalTooltip: View {
    let chart: WeekChart
    /// The chart's providers, in its order.
    let providers: [ProviderDescriptor]
    @Environment(\.locale) private var locale

    var body: some View {
        ChartTooltip(
            title: Copy.thisCycle,
            rows: providers.compactMap { provider in
                chart.cycleTotals[provider.id].map { total in
                    ChartTooltip.Row(
                        provider: provider,
                        tokens: total.tokens,
                        detail: Copy.since(DayLabelFormatter(locale: locale).monthDay(for: total.since))
                    )
                }
            }
        )
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        CycleTotalTooltip(chart: PreviewValues.chart, providers: [PreviewValues.northwind, PreviewValues.tailspin])
            .padding(DesignTokens.Insets.weekChart)
    }
}
#endif
