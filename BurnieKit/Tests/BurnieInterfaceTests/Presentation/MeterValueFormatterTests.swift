import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct MeterValueFormatterTests {
    let formatter = MeterValueFormatter(locale: .enUS)

    @Test func percentHasNoLimit() {
        #expect(formatter.parts(for: .percent(64)) == ("64%", nil))
    }

    @Test func moneyShowsUsedOverLimit() {
        #expect(formatter.parts(for: .money(used: Cents(1_340), limit: Cents(2_000))) == ("$13.40", " / $20"))
        #expect(formatter.parts(for: .money(used: Cents(0), limit: nil)) == ("$0.00", " / No limit"))
    }
}
