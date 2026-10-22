import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct WeekChartAccessibilityValueTests {
    static let today = LocalDay.day("2026-10-10")

    static var chart: WeekChart {
        var history = UsageHistory()
        history.record([today: Tokens(1_800_000), .day("2026-10-08"): Tokens(400_000)], for: .alpha, today: today)
        history.record([today: Tokens(2_600_000)], for: .beta, today: today)
        return WeekChart.make(history: history, providers: [.alpha, .beta], today: today, spent: [.beta: [today: Cents(412), .day("2026-10-09"): .zero]])
    }

    @Test("B-77 VoiceOver reads the week totals, then every day; B-78 with each day's spend where it's known")
    func readsTheTotalsThenEveryDay() {
        let text = WeekChartAccessibilityValue.text(for: Self.chart, providers: [.alpha, .beta], locale: .enUS)
        #expect(text == [
            "Last 7 days: Alpha 2.2M tokens, Beta 2.6M tokens",
            "Sun: Alpha 0 tokens, Beta 0 tokens",
            "Mon: Alpha 0 tokens, Beta 0 tokens",
            "Tue: Alpha 0 tokens, Beta 0 tokens",
            "Wed: Alpha 0 tokens, Beta 0 tokens",
            "Thu: Alpha 400K tokens, Beta 0 tokens",
            "Fri: Alpha 0 tokens, Beta 0 tokens ($0.00)",
            "Sat: Alpha 1.8M tokens, Beta 2.6M tokens ($4.12)",
        ].joined(separator: "; "))
    }
}
