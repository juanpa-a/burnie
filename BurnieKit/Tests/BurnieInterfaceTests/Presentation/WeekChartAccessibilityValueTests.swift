import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct WeekChartAccessibilityValueTests {
    static let today = LocalDay.day("2026-10-10")

    static var history: UsageHistory {
        var history = UsageHistory()
        history.record([today: Tokens(1_800_000), .day("2026-10-08"): Tokens(400_000)], for: .alpha, today: today)
        history.record([today: Tokens(2_600_000)], for: .beta, today: today)
        return history
    }

    static var chart: WeekChart {
        WeekChart.make(
            history: history,
            providers: [.alpha, .beta],
            today: today,
            spent: [.beta: [today: Cents(412), .day("2026-10-09"): .zero]],
            cycleStarts: [.alpha: .day("2026-10-01"), .beta: .day("2026-10-01")]
        )
    }

    @Test("B-76 VoiceOver reads the cycle totals, then every day; B-77 B-78 with each day's spend where it's known")
    func readsTheCycleTotalsThenEveryDay() {
        let text = WeekChartAccessibilityValue.text(for: Self.chart, providers: [.alpha, .beta], locale: .enUS)
        #expect(text == [
            "This cycle: Alpha 2.2M tokens, Beta 2.6M tokens",
            "Sun: Alpha 0 tokens, Beta 0 tokens",
            "Mon: Alpha 0 tokens, Beta 0 tokens",
            "Tue: Alpha 0 tokens, Beta 0 tokens",
            "Wed: Alpha 0 tokens, Beta 0 tokens",
            "Thu: Alpha 400K tokens, Beta 0 tokens",
            "Fri: Alpha 0 tokens, Beta 0 tokens ($0.00)",
            "Sat: Alpha 1.8M tokens, Beta 2.6M tokens ($4.12)",
        ].joined(separator: "; "))
    }

    @Test("B-76 VoiceOver leaves out a provider without a cycle total, and the cycle part without any")
    func leavesOutProvidersWithoutACycleTotal() {
        let oneCycle = WeekChart.make(history: Self.history, providers: [.alpha, .beta], today: Self.today, cycleStarts: [.beta: .day("2026-10-08")])
        let noCycle = WeekChart.make(history: Self.history, providers: [.alpha, .beta], today: Self.today)
        #expect(WeekChartAccessibilityValue.text(for: oneCycle, providers: [.alpha, .beta], locale: .enUS).hasPrefix("This cycle: Beta 2.6M tokens; Sun: "))
        #expect(WeekChartAccessibilityValue.text(for: noCycle, providers: [.alpha, .beta], locale: .enUS).hasPrefix("Sun: "))
    }
}
