import Testing
import LegacyTestSupport
@testable import BurnieCore

struct MoneyFormatterTests {
    let formatter = MoneyFormatter(locale: .enUS)

    @Test func amountsAlwaysShowCents() {
        #expect(formatter.amount(cents: 106) == "$1.06")
        #expect(formatter.amount(cents: 1_340) == "$13.40")
        #expect(formatter.amount(cents: 0) == "$0.00")
    }

    @Test func limitsDropCentsOnlyWhenWhole() {
        #expect(formatter.limit(cents: 2_000) == "$20")
        #expect(formatter.limit(cents: 1_250) == "$12.50")
    }
}
