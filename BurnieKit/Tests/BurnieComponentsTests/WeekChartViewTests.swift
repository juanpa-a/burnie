import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import SwiftUI
import Testing
@testable import BurnieComponents

/// What the week chart's tooltips draw over, read off its rendered pixels.
@MainActor
struct WeekChartViewTests {
    static let width: CGFloat = 340
    static let today = LocalDay.day("2026-10-10")
    /// The chart's right edge, where both the legend and the last day's tooltip end.
    static let trailingEdge = Int(width - DesignTokens.Insets.weekChart.trailing)

    /// One provider with spend, so the last day's tooltip is wide and rises over the end of the legend.
    static var chart: WeekChart {
        var history = UsageHistory()
        history.record([today: Tokens(283_000_000), .day("2026-10-08"): Tokens(197_000_000)], for: .beta, today: today)
        return WeekChart.make(history: history, providers: [.beta], today: today, spent: [.beta: [today: Cents(3_065)]])
    }

    @Test("B-77 a day's tooltip draws over the legend it rises over", arguments: [ColorScheme.light, .dark])
    func dayTooltipCoversTheLegend(scheme: ColorScheme) throws {
        let view = WeekChartView(chart: Self.chart, descriptors: [.beta], hoveredDay: Self.today)
        let chart = try #require(RenderedImage(view.environment(\.colorScheme, scheme), width: Self.width))
        let background = try #require(RenderedImage(DesignTokens.Palette.pop.environment(\.colorScheme, scheme), width: 1))
            .color(atX: 0, y: 0)
        // The tooltip's right padding, across the legend's row: the end of the week total is drawn there unless the
        // tooltip covers it.
        let padding = Int(DesignTokens.Insets.tooltip.trailing)
        let legendRow = Int(DesignTokens.Insets.weekChart.top)...Int(DesignTokens.Insets.weekChart.top) + 12
        for x in (Self.trailingEdge - padding + 1)..<(Self.trailingEdge - 1) {
            for y in legendRow {
                let drawn = chart.color(atX: x, y: y)
                #expect(drawn.isClose(to: background), "\(scheme) at x \(x), y \(y): drew \(drawn), not the tooltip's \(background)")
            }
        }
    }
}
