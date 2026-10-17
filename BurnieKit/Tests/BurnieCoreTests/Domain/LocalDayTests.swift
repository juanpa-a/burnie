import Foundation
import Testing
import LegacyTestSupport
@testable import BurnieCore

struct LocalDayTests {
    static let anchor = LocalDay.day("2026-10-10")
    /// About five and a half years either way, so steps cross month ends, year ends and leap days.
    static let steps = -2_000...2_000

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

    @Test(arguments: Gen.seeds(200))
    func steppingBackUndoesAdvancing(seed: UInt64) {
        var gen = Gen(seed: seed)
        let day = gen.localDay(around: Self.anchor)
        let step = gen.int(in: Self.steps)
        #expect(day.advanced(by: step).advanced(by: -step) == day, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func distanceToAnAdvancedDayIsTheStep(seed: UInt64) {
        var gen = Gen(seed: seed)
        let day = gen.localDay(around: Self.anchor)
        let step = gen.int(in: Self.steps)
        #expect(day.distance(to: day.advanced(by: step)) == step, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func isoRoundTrips(seed: UInt64) {
        var gen = Gen(seed: seed)
        let day = Self.anchor.advanced(by: gen.int(in: Self.steps))
        #expect(LocalDay(iso: day.iso) == day, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func orderingAgreesWithDistance(seed: UInt64) {
        var gen = Gen(seed: seed)
        let day = Self.anchor.advanced(by: gen.int(in: Self.steps))
        // Close days, so about a seventh are the same day and some cross a month or year end.
        let other = day.advanced(by: gen.int(in: -3...3))
        #expect((day < other) == (day.distance(to: other) > 0), "seed \(seed)")
        #expect((day == other) == (day.distance(to: other) == 0), "seed \(seed)")
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

    @Test("B-41 the activity window is today and the 7 days before")
    func activityWindowCoversTodayAndTheSevenDaysBefore() {
        let window = ActivityWindow.days(endingAt: .day("2026-10-10"))
        #expect(window.lowerBound.iso == "2026-10-03")
        #expect(window.count == 8)
    }
}
