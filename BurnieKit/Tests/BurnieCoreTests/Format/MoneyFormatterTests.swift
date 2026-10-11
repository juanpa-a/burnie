import Testing
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

struct MeterValueFormatterTests {
    let formatter = MeterValueFormatter(locale: .enUS)

    @Test func percentHasNoLimit() {
        #expect(formatter.parts(for: .percent(64)) == ("64%", nil))
    }

    @Test func moneyShowsUsedOverLimit() {
        #expect(formatter.parts(for: .money(usedCents: 1_340, limitCents: 2_000)) == ("$13.40", " / $20"))
        #expect(formatter.parts(for: .money(usedCents: 0, limitCents: nil)) == ("$0.00", " / No limit"))
    }
}
