import BurnieDomain
import BurnieInterface
import SwiftUI

/// One day of the week chart, over its column while it's hovered: the day, then each provider's tokens (B-77).
struct WeekChartTooltip: View {
    let chart: WeekChart
    let day: LocalDay
    /// The chart's providers, in its order.
    let providers: [ProviderDescriptor]
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tooltipLines) {
            Text(DayLabelFormatter(locale: locale).shortDate(for: day))
                .font(DesignTokens.Typography.captionStrong)
                .foregroundStyle(DesignTokens.Palette.fg)
            ForEach(providers, id: \.id) { provider in
                row(provider)
            }
        }
        .padding(DesignTokens.Insets.tooltip)
        .background(DesignTokens.Palette.pop, in: shape)
        .overlay(shape.strokeBorder(DesignTokens.Palette.line, lineWidth: DesignTokens.Metrics.tooltipBorder))
        .shadow(
            color: DesignTokens.Palette.tooltipShadow,
            radius: DesignTokens.Metrics.tooltipShadowRadius,
            y: DesignTokens.Metrics.tooltipShadowOffset
        )
        .fixedSize()
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Metrics.tooltipRadius)
    }

    private func row(_ provider: ProviderDescriptor) -> some View {
        HStack(spacing: DesignTokens.Spacing.legendDot) {
            LegendDot(color: provider.color)
            Text(provider.shortName)
                .foregroundStyle(DesignTokens.Palette.fg2)
            Spacer(minLength: DesignTokens.Spacing.tooltipValues)
            Text(TokenCountFormatter(locale: locale).string(from: chart.tokens(of: provider.id, on: day)))
                .foregroundStyle(DesignTokens.Palette.fg)
        }
        .font(DesignTokens.Typography.caption)
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
