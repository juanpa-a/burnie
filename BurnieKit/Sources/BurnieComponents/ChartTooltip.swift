import BurnieDomain
import BurnieInterface
import SwiftUI

/// A tooltip of the week chart: a title, then one row per provider with its tokens and, where there's one, a detail in
/// a quieter color, in a box that lifts off the popover (B-77, B-80).
struct ChartTooltip: View {
    /// One provider's line.
    struct Row {
        let provider: ProviderDescriptor
        let tokens: Tokens
        /// After the tokens: the day's spend, the day a cycle total counts from.
        let detail: String?
    }

    let title: String
    /// In the chart's order.
    let rows: [Row]
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.tooltipLines) {
            Text(title)
                .font(DesignTokens.Typography.captionStrong)
                .foregroundStyle(DesignTokens.Palette.fg)
            ForEach(rows, id: \.provider.id) { row in
                line(row)
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

    private func line(_ row: Row) -> some View {
        HStack(spacing: DesignTokens.Spacing.legendDot) {
            LegendDot(color: row.provider.color)
            Text(row.provider.shortName)
                .foregroundStyle(DesignTokens.Palette.fg2)
            Spacer(minLength: DesignTokens.Spacing.tooltipValues)
            Text(TokenCountFormatter(locale: locale).string(from: row.tokens))
                .foregroundStyle(DesignTokens.Palette.fg)
            if let detail = row.detail {
                Text(detail)
                    .foregroundStyle(DesignTokens.Palette.fg2)
            }
        }
        .font(DesignTokens.Typography.caption)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        ChartTooltip(
            title: PreviewValues.tooltipTitle,
            rows: [
                ChartTooltip.Row(provider: PreviewValues.northwind, tokens: Tokens(1_250_000), detail: nil),
                ChartTooltip.Row(provider: PreviewValues.tailspin, tokens: Tokens(2_400_000), detail: PreviewValues.tooltipDetail),
            ]
        )
        .padding(DesignTokens.Insets.weekChart)
    }
}
#endif
