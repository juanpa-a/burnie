import Testing
import LegacyTestSupport
@testable import BurnieCore

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
