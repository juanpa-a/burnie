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

    @Test("B-77 the tooltip names its day and the day of the month")
    func tooltipDatesNameTheDayAndItsNumber() {
        #expect(DayLabelFormatter(locale: .enUS).shortDate(for: .day("2026-10-10")) == "Sat 10")
        #expect(DayLabelFormatter(locale: .enUS).shortDate(for: .day("2026-10-19")) == "Mon 19")
    }
}
