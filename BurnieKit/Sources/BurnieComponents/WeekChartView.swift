import BurnieDomain
import BurnieInterface
import SwiftUI

/// Tokens over the last 7 days: one bar per provider for each day, every series on one shared scale, so the same
/// tokens draw the same height for every provider (B-43).
public struct WeekChartView: View {
    let chart: WeekChart
    /// The descriptors of the chart's providers, for their short names and colors.
    let descriptors: [ProviderDescriptor]
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    public init(chart: WeekChart, descriptors: [ProviderDescriptor]) {
        self.chart = chart
        self.descriptors = descriptors
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.chartRows) {
            HStack {
                Text(Copy.lastSevenDays)
                    .font(DesignTokens.Typography.captionStrong)
                    .tracking(DesignTokens.Typography.chartTitleTracking)
                    .foregroundStyle(DesignTokens.Palette.fg2)
                Spacer()
                legend
            }
            HStack(spacing: DesignTokens.Spacing.chartColumns) {
                ForEach(chart.days.indices, id: \.self) { index in
                    column(index)
                }
            }
        }
        .padding(DesignTokens.Insets.weekChart)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.weekChartAccessibilityLabel)
        .accessibilityValue(accessibilitySummary)
    }

    /// The chart's providers, in its order, with what the legend shows of each.
    private var shown: [ProviderDescriptor] {
        chart.providers.compactMap { id in descriptors.first { $0.id == id } }
    }

    private var legend: some View {
        HStack(spacing: DesignTokens.Spacing.legendItems) {
            ForEach(shown, id: \.id) { descriptor in
                HStack(spacing: DesignTokens.Spacing.legendDot) {
                    Circle()
                        .fill(DesignTokens.Palette.accent(descriptor.color, in: colorScheme))
                        .frame(width: DesignTokens.Metrics.legendDot, height: DesignTokens.Metrics.legendDot)
                    Text(descriptor.shortName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Palette.fg2)
                }
            }
        }
    }

    private func column(_ index: Int) -> some View {
        let isToday = index == chart.days.count - 1
        return VStack(spacing: DesignTokens.Spacing.chartLabel) {
            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.chartBars) {
                ForEach(shown, id: \.id) { descriptor in
                    bar(descriptor, day: index)
                }
            }
            .frame(height: DesignTokens.Metrics.chartHeight, alignment: .bottom)
            Text(DayLabelFormatter(locale: locale).letter(for: chart.days[index]))
                .font(isToday ? DesignTokens.Typography.today : DesignTokens.Typography.day)
                .foregroundStyle(isToday ? DesignTokens.Palette.fg : DesignTokens.Palette.fg2)
        }
        .frame(maxWidth: .infinity)
    }

    /// A day without usage gets a `track` mark of the minimum height; a day with usage is never shorter than it.
    private func bar(_ descriptor: ProviderDescriptor, day: Int) -> some View {
        let tokens = tokens(of: descriptor.id, on: day)
        let minimum = DesignTokens.Metrics.chartBarMinimum
        let height = tokens > .zero
            ? max(CGFloat(tokens.count) / CGFloat(chart.peak.count) * DesignTokens.Metrics.chartHeight, minimum)
            : minimum
        return RoundedRectangle(cornerRadius: DesignTokens.Metrics.chartBarRadius)
            .fill(tokens > .zero ? DesignTokens.Palette.accent(descriptor.color, in: colorScheme) : DesignTokens.Palette.track)
            .frame(width: DesignTokens.Metrics.chartBarWidth, height: height)
    }

    private func tokens(of provider: ProviderID, on day: Int) -> Tokens {
        chart.series[provider]?[day] ?? .zero
    }

    /// "Sat: Claude 1.8M tokens, Cursor 2.6M tokens; Sun: …"
    private var accessibilitySummary: String {
        let formatter = TokenCountFormatter(locale: locale)
        let dayNames = DayLabelFormatter(locale: locale)
        return chart.days.indices.map { index in
            let usage = shown.map { Copy.dayUsage(provider: $0.shortName, tokens: formatter.string(from: tokens(of: $0.id, on: index))) }
            return "\(dayNames.shortName(for: chart.days[index])): \(usage.joined(separator: ", "))"
        }
        .joined(separator: "; ")
    }
}

#Preview {
    PreviewFrame {
        WeekChartView(chart: PreviewValues.chart, descriptors: [PreviewValues.northwind, PreviewValues.tailspin])
    }
}
