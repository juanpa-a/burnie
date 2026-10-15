import Foundation
import Testing
@testable import BurnieCore

struct CursorSpendMapperTests {
    static let today = LocalDay.day("2026-10-10")
    let calendar = Calendar.gregorian(in: .mexicoCity)

    func spent(_ eventsJSON: String) throws(ProviderIssue) -> [LocalDay: Int] {
        let events = try! JSONDecoder().decode([CursorUsageEventsDTO.Event].self, from: Data(eventsJSON.utf8))
        return try CursorSpendMapper.dailySpentCents(from: events, in: Self.today...Self.today, calendar: calendar)
    }

    @Test func fractionsOfACentAddUpBeforeRounding() throws {
        let tenAM = #"{"timestamp":"1791648000000","chargedCents":0.4}"#
        #expect(try spent("[\(tenAM),\(tenAM),\(tenAM)]") == [Self.today: 1])
    }

    @Test func numbersMayArriveAsStrings() throws {
        #expect(try spent(#"[{"timestamp":1791648000000,"chargedCents":"250"}]"#) == [Self.today: 250])
    }

    @Test func aDayWithoutEventsSpentNothing() throws {
        #expect(try spent("[]") == [Self.today: 0])
    }

    @Test func eventsOutsideTheDaysAreIgnored() throws {
        // 23:00 on the 9th in Mexico City.
        #expect(try spent(#"[{"timestamp":"1791608400000","chargedCents":99}]"#) == [Self.today: 0])
    }

    @Test(arguments: [
        #"[{"timestamp":"1791648000000"}]"#,
        #"[{"timestamp":"1791648000000","chargedCents":null}]"#,
        #"[{"timestamp":"1791648000000","chargedCents":"NaN"}]"#,
        #"[{"timestamp":"1791648000000","chargedCents":-5}]"#,
        #"[{"chargedCents":5}]"#,
    ])
    func oneEventWithoutAValidChargeMakesTheSumUnknown(eventsJSON: String) {
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor event without a valid charge")) { try spent(eventsJSON) }
    }
}
