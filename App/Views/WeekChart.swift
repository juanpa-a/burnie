import BurnieCore
import SwiftUI

/// Tokens over the last 7 days: one bar per enabled provider for each day.
/// Each series is scaled against its own maximum: the chart compares shape, not magnitude.
struct WeekChart: View {
    let providers: [ProviderID]
    /// 7 points per provider, ending today.
    let history: [ProviderID: [DailyPoint]]
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Last 7 days")
                    .font(Tokens.Typography.captionStrong)
                    .tracking(0.2)
                    .foregroundStyle(Tokens.Palette.fg2)
                Spacer()
                legend
            }
            HStack(spacing: 6) {
                ForEach(days.indices, id: \.self) { index in
                    column(index)
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 14, trailing: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily usage, last 7 days")
        .accessibilityValue(accessibilitySummary)
    }

    private var legend: some View {
        HStack(spacing: 10) {
            ForEach(providers, id: \.self) { provider in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Tokens.Palette.accent(provider))
                        .frame(width: Tokens.Metrics.legendDot, height: Tokens.Metrics.legendDot)
                    Text(provider.shortName)
                        .font(Tokens.Typography.caption)
                        .foregroundStyle(Tokens.Palette.fg2)
                }
            }
        }
    }

    private func column(_ index: Int) -> some View {
        let isToday = index == days.count - 1
        return VStack(spacing: 5) {
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(providers, id: \.self) { provider in
                    bar(provider, dayIndex: index)
                }
            }
            .frame(height: Tokens.Metrics.chartHeight, alignment: .bottom)
            Text(DayLabelFormatter(locale: locale).letter(for: days[index]))
                .font(isToday ? Tokens.Typography.today : Tokens.Typography.day)
                .foregroundStyle(isToday ? Tokens.Palette.fg : Tokens.Palette.fg2)
        }
        .frame(maxWidth: .infinity)
    }

    /// A day without usage gets a 2 pt `track` mark; a day with usage is never shorter than 2 pt.
    private func bar(_ provider: ProviderID, dayIndex: Int) -> some View {
        let values = series(provider)
        let value = values[dayIndex]
        let peak = values.max() ?? 0
        let height = value > 0 ? max(CGFloat(value) / CGFloat(peak) * Tokens.Metrics.chartHeight, Tokens.Metrics.chartBarMinimum) : Tokens.Metrics.chartBarMinimum
        return RoundedRectangle(cornerRadius: Tokens.Metrics.chartBarRadius)
            .fill(value > 0 ? Tokens.Palette.accent(provider) : Tokens.Palette.track)
            .frame(width: Tokens.Metrics.chartBarWidth, height: height)
    }

    /// Every series shares the same 7 days.
    private var days: [LocalDay] {
        providers.first.flatMap { history[$0] }?.map(\.day) ?? []
    }

    private func series(_ provider: ProviderID) -> [Int] {
        history[provider]?.map(\.value) ?? Array(repeating: 0, count: days.count)
    }

    /// "Sat: Claude 1.8M tokens, Cursor 2.6M tokens; Sun: …"
    private var accessibilitySummary: String {
        let tokens = TokenCountFormatter(locale: locale)
        let dayNames = DayLabelFormatter(locale: locale)
        return days.indices.map { index in
            let usage = providers.map { "\($0.shortName) \(tokens.string(from: series($0)[index])) tokens" }
            return "\(dayNames.shortName(for: days[index])): \(usage.joined(separator: ", "))"
        }
        .joined(separator: "; ")
    }
}
