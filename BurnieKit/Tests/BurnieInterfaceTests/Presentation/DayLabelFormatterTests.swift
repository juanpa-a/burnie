import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct DayLabelFormatterTests {
    @Test func daysAreLabeledInTheLocale() {
        let saturday = LocalDay.day("2026-10-10")
        #expect(DayLabelFormatter(locale: .enUS).letter(for: saturday) == "S")
        #expect(DayLabelFormatter(locale: .enUS).shortName(for: saturday) == "Sat")
        #expect(DayLabelFormatter(locale: Locale(identifier: "es_MX")).letter(for: saturday) == "S")
        #expect(DayLabelFormatter(locale: .enUS).letter(for: .day("2026-10-14")) == "W")
    }
}
