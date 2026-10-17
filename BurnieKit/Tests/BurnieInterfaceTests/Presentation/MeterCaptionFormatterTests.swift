import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieInterface

struct MeterCaptionFormatterTests {
    let formatter = MeterCaptionFormatter(locale: .enUS, timeZone: .mexicoCity)
    let now = Date.iso("2026-10-11T18:00:00Z") // Sun Oct 11, 12:00 PM in Mexico City

    @Test(arguments: [
        (8_040.0 + 59, "Resets in 2h 14m"),
        (2_700.0, "Resets in 45m"),
        (3_600.0, "Resets in 1h 0m"),
        (30.0, "Resets in <1m"),
        (-120.0, "Resets in <1m"),
    ])
    func sessionCountsDownInHoursAndMinutes(secondsLeft: TimeInterval, expected: String) {
        #expect(formatter.string(for: .resetsIn(now.addingTimeInterval(secondsLeft)), now: now) == expected)
    }

    @Test func weeklyShowsWeekdayAndLocalTime() {
        let thursdayNineAM = Date.iso("2026-10-15T15:00:00Z")
        #expect(formatter.string(for: .resetsAt(thursdayNineAM), now: now) == "Resets Thu, 9:00\u{202F}AM")
    }

    @Test func cycleShowsEndDateAndDaysLeft() {
        #expect(formatter.string(for: .cycleEnds(.iso("2026-11-01T22:00:00Z")), now: now) == "Resets Nov 1 · 21 days left")
        #expect(formatter.string(for: .cycleEnds(.iso("2026-10-12T22:00:00Z")), now: now) == "Resets Oct 12 · 1 day left")
        #expect(formatter.string(for: .cycleEnds(.iso("2026-10-11T23:00:00Z")), now: now) == "Resets today")
    }

    @Test func fixedCaptions() {
        #expect(formatter.string(for: .noActiveSession, now: now) == "No active session")
        #expect(formatter.string(for: .onDemandIdle, now: now) == "Kicks in after included usage runs out")
    }
}
