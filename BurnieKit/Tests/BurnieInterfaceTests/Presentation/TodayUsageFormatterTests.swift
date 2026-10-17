import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct TodayUsageFormatterTests {
    let formatter = TodayUsageFormatter(locale: .enUS)

    @Test func tokenPlansCountTokens() {
        #expect(formatter.string(for: .tokens(Tokens(25_300_000))) == "25M tokens today")
        #expect(formatter.string(for: .tokens(.zero)) == "0 tokens today")
    }

    @Test func dollarPlansShowTheSpend() {
        #expect(formatter.string(for: .money(Cents(1_240))) == "$12.40 today")
        #expect(formatter.string(for: .money(.zero)) == "$0.00 today")
    }
}
