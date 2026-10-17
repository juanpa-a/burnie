import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct MoneyFormatterTests {
    let formatter = MoneyFormatter(locale: .enUS)

    @Test func amountsAlwaysShowCents() {
        #expect(formatter.amount(Cents(106)) == "$1.06")
        #expect(formatter.amount(Cents(1_340)) == "$13.40")
        #expect(formatter.amount(Cents(0)) == "$0.00")
    }

    @Test func limitsDropCentsOnlyWhenWhole() {
        #expect(formatter.limit(Cents(2_000)) == "$20")
        #expect(formatter.limit(Cents(1_250)) == "$12.50")
    }
}
