import BurnieDomain
import BurnieInterface
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieProviders

struct CursorUsageEventsTests {
    let window = ActivityWindow.days(endingAt: .day("2026-10-10"))
    let calendar = Calendar.gregorian(in: .mexicoCity)

    @Test("B-47 tokens are the CSV's Total Tokens per local day inside the window")
    func sumsTotalTokensPerLocalDayInsideTheWindow() throws {
        let totals = try CursorUsageEvents.dailyTokens(csv: Fixture.text("cursor-events.csv"), in: window, calendar: calendar)
        #expect(totals == [
            .day("2026-10-10"): Tokens(2_662_000), // includes two events at 01:xx UTC on the 11th
            .day("2026-10-09"): Tokens(29_200),    // 05:30 UTC on the 10th
            .day("2026-10-08"): Tokens(29_200),
            .day("2026-10-04"): Tokens(10),
        ])
    }

    @Test func emptyExportHasNoTokens() throws {
        #expect(try CursorUsageEvents.dailyTokens(csv: "", in: window, calendar: calendar).isEmpty)
    }

    @Test func exportWithoutTheExpectedColumnsIsUnexpected() {
        #expect(throws: ProviderIssue.unexpectedResponse("Cursor CSV without Date or Total Tokens")) {
            try CursorUsageEvents.dailyTokens(csv: "When,Tokens\n", in: window, calendar: calendar)
        }
    }
}
