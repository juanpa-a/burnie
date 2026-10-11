import Foundation
import Testing
@testable import BurnieCore

struct LocalDayTests {
    @Test func earlyUTCMorningFallsOnThePreviousDayInMexicoCity() {
        #expect(LocalDay(.iso("2026-10-10T05:30:00Z"), in: .mexicoCity).iso == "2026-10-09")
        #expect(LocalDay(.iso("2026-10-10T06:00:00Z"), in: .mexicoCity).iso == "2026-10-10")
    }

    @Test(arguments: [
        ("2026-11-01T03:59:00Z", "2026-10-31"), // 23:59 EDT
        ("2026-11-01T04:00:00Z", "2026-11-01"), // 00:00 EDT, the day of the change
        ("2026-11-02T04:59:00Z", "2026-11-01"), // 23:59 EST, the day had 25 hours
        ("2026-11-02T05:00:00Z", "2026-11-02"),
        ("2026-03-09T03:59:00Z", "2026-03-08"), // 23:59 EDT, the day had 23 hours
    ])
    func bucketsAcrossNewYorkDaylightSavingChanges(timestamp: String, day: String) {
        #expect(LocalDay(.iso(timestamp), in: .newYork).iso == day)
    }

    @Test func stepsByCalendarDays() {
        let day = LocalDay.day("2026-10-30")
        #expect(day.advanced(by: 3).iso == "2026-11-02")
        #expect(day.advanced(by: -30).iso == "2026-09-30")
        #expect(day.distance(to: .day("2026-11-01")) == 2)
    }

    @Test func rejectsMalformedDays() {
        #expect(LocalDay(iso: "2026-02-30") == nil)
        #expect(LocalDay(iso: "2026-1-5") == nil)
        #expect(LocalDay(iso: "yesterday") == nil)
    }

    @Test func encodesAsPlainStringsAndDictionaryKeys() throws {
        let days = [LocalDay.day("2026-10-10"): 1_250_000]
        let json = String(decoding: try JSONEncoder().encode(days), as: UTF8.self)
        #expect(json == #"{"2026-10-10":1250000}"#)
        #expect(try JSONDecoder().decode([LocalDay: Int].self, from: Data(json.utf8)) == days)
    }

    @Test func activityWindowCoversTodayAndTheSevenDaysBefore() {
        let window = ActivityWindow.days(endingAt: .day("2026-10-10"))
        #expect(window.lowerBound.iso == "2026-10-03")
        #expect(window.count == 8)
    }
}
