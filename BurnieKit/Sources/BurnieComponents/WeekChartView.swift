import BurnieDomain
import BurnieInterface
import SwiftUI

/// Tokens over the last 7 days: one bar per provider for each day, every series on one shared scale, so the same
/// tokens draw the same height for every provider (B-43). The legend shows each provider's week total (B-76), and
/// hovering it shows the cycle totals (B-80); hovering a day dims the others and shows that day's tooltip (B-77).
public struct WeekChartView: View {
    /// How many days at each end line their tooltip up with their outer edge instead of centering it, so it stays
    /// inside the chart.
    private static let edgeDays = 2

    let chart: WeekChart
    /// The descriptors of the chart's providers, for their short names and colors.
    let descriptors: [ProviderDescriptor]
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    /// The day under the pointer, which shows its tooltip.
    @State private var hoveredDay: LocalDay?
    /// Whether the pointer is over the legend, which shows the cycle totals.
    @State private var isLegendHovered = false

    public init(chart: WeekChart, descriptors: [ProviderDescriptor]) {
        self.init(chart: chart, descriptors: descriptors, hoveredDay: nil)
    }

    /// Starting with `hoveredDay`'s tooltip, or the legend's, already shown: for the previews and the tests that look
    /// at a tooltip.
    init(chart: WeekChart, descriptors: [ProviderDescriptor], hoveredDay: LocalDay?, isLegendHovered: Bool = false) {
        self.chart = chart
        self.descriptors = descriptors
        _hoveredDay = State(initialValue: hoveredDay)
        _isLegendHovered = State(initialValue: isLegendHovered)
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
            // Each tooltip crosses into the other row: the cycle totals hang over the columns, a day's rises over the legend.
            // Whichever row shows its tooltip draws on top.
            .zIndex(isLegendHovered ? 1 : 0)
            HStack(spacing: DesignTokens.Spacing.chartColumns) {
                ForEach(chart.days, id: \.self) { day in
                    column(day)
                }
            }
            // The gaps between days belong to the chart, so crossing one keeps the tooltip of the day just left.
            .contentShape(Rectangle())
            .onHover { isInside in
                if !isInside { hoveredDay = nil }
            }
            .animation(DesignTokens.Motion.chartHover, value: hoveredDay)
        }
        .padding(DesignTokens.Insets.weekChart)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.weekChartAccessibilityLabel)
        .accessibilityValue(WeekChartAccessibilityValue.text(for: chart, providers: shown, locale: locale))
    }

    /// The chart's providers, in its order, with what the legend shows of each.
    private var shown: [ProviderDescriptor] {
        chart.providers.compactMap { id in descriptors.first { $0.id == id } }
    }

    private var legend: some View {
        HStack(spacing: DesignTokens.Spacing.legendItems) {
            ForEach(shown, id: \.id) { descriptor in
                HStack(spacing: DesignTokens.Spacing.legendDot) {
                    LegendDot(color: descriptor.color)
                    Text(descriptor.shortName)
                        .foregroundStyle(DesignTokens.Palette.fg2)
                    Text(TokenCountFormatter(locale: locale).string(from: chart.total(for: descriptor.id)))
                        .foregroundStyle(DesignTokens.Palette.fg)
                }
                .font(DesignTokens.Typography.caption)
            }
        }
        .onHover { isLegendHovered = $0 }
        .overlay(alignment: .bottomTrailing) {
            if isLegendHovered && !chart.cycleTotals.isEmpty {
                // A line along the legend's bottom, with the tooltip hanging from it over the columns.
                Color.clear
                    .frame(height: 0)
                    .overlay(alignment: .topTrailing) {
                        CycleTotalTooltip(chart: chart, providers: shown)
                            .padding(.top, DesignTokens.Spacing.tooltipGap)
                    }
                    .allowsHitTesting(false)
            }
        }
        .animation(DesignTokens.Motion.chartHover, value: isLegendHovered)
    }

    private func column(_ day: LocalDay) -> some View {
        let isToday = day == chart.days.last
        let isDimmed = hoveredDay != nil && hoveredDay != day
        return VStack(spacing: DesignTokens.Spacing.chartLabel) {
            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.chartBars) {
                ForEach(shown, id: \.id) { descriptor in
                    bar(descriptor, on: day)
                }
            }
            .frame(height: DesignTokens.Metrics.chartHeight, alignment: .bottom)
            Text(DayLabelFormatter(locale: locale).letter(for: day))
                .font(isToday ? DesignTokens.Typography.today : DesignTokens.Typography.day)
                .foregroundStyle(isToday ? DesignTokens.Palette.fg : DesignTokens.Palette.fg2)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .opacity(isDimmed ? DesignTokens.Opacity.chartDimmed : DesignTokens.Opacity.opaque)
        .onHover { isInside in
            if isInside { hoveredDay = day }
        }
        .overlay(alignment: .top) {
            if hoveredDay == day {
                // A line along the day's top, with the tooltip standing on it: it rises over the title row.
                Color.clear
                    .frame(height: 0)
                    .overlay(alignment: tooltipAlignment(for: day)) {
                        WeekChartTooltip(chart: chart, day: day, providers: shown)
                            .padding(.bottom, DesignTokens.Spacing.tooltipGap)
                    }
                    .allowsHitTesting(false)
            }
        }
    }

    /// Centered over its day, except at the ends, where it lines up with the day's outer edge.
    private func tooltipAlignment(for day: LocalDay) -> Alignment {
        guard let index = chart.days.firstIndex(of: day) else { return .bottom }
        if index < Self.edgeDays { return .bottomLeading }
        if index >= chart.days.count - Self.edgeDays { return .bottomTrailing }
        return .bottom
    }

    /// A day without usage gets a `track` mark of the minimum height; a day with usage is never shorter than it.
    private func bar(_ descriptor: ProviderDescriptor, on day: LocalDay) -> some View {
        let tokens = chart.tokens(of: descriptor.id, on: day)
        let minimum = DesignTokens.Metrics.chartBarMinimum
        let height = tokens > .zero
            ? max(CGFloat(tokens.count) / CGFloat(chart.peak.count) * DesignTokens.Metrics.chartHeight, minimum)
            : minimum
        return RoundedRectangle(cornerRadius: DesignTokens.Metrics.chartBarRadius)
            .fill(tokens > .zero ? DesignTokens.Palette.accent(descriptor.color, in: colorScheme) : DesignTokens.Palette.track)
            .frame(width: DesignTokens.Metrics.chartBarWidth, height: height)
    }
}

#if DEBUG
#Preview {
    PreviewFrame {
        WeekChartView(chart: PreviewValues.chart, descriptors: [PreviewValues.northwind, PreviewValues.tailspin])
    }
}

#Preview("Day hovered") {
    PreviewFrame {
        WeekChartView(chart: PreviewValues.chart, descriptors: [PreviewValues.northwind, PreviewValues.tailspin], hoveredDay: PreviewValues.today)
    }
}

#Preview("Legend hovered") {
    PreviewFrame {
        WeekChartView(chart: PreviewValues.chart, descriptors: [PreviewValues.northwind, PreviewValues.tailspin], hoveredDay: nil, isLegendHovered: true)
    }
}
#endif
