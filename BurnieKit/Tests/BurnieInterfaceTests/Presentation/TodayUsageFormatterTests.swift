import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct TodayUsageFormatterTests {
    let formatter = TodayUsageFormatter(locale: .enUS)

    @Test func countsTodaysTokens() {
        #expect(formatter.string(for: TodayUsage(tokens: Tokens(25_300_000))) == "25M tokens today")
        #expect(formatter.string(for: TodayUsage(tokens: .zero)) == "0 tokens today")
    }
}
