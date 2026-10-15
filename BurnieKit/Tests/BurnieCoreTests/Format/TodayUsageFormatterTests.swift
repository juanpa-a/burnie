import Testing
@testable import BurnieCore

struct TodayUsageFormatterTests {
    let formatter = TodayUsageFormatter(locale: .enUS)

    @Test func tokenPlansCountTokens() {
        #expect(formatter.string(for: .tokens(25_300_000)) == "25M tokens today")
        #expect(formatter.string(for: .tokens(0)) == "0 tokens today")
    }

    @Test func dollarPlansShowTheSpend() {
        #expect(formatter.string(for: .money(cents: 1_240)) == "$12.40 today")
        #expect(formatter.string(for: .money(cents: 0)) == "$0.00 today")
    }
}
