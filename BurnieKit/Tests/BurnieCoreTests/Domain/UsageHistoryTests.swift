import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct UsageHistoryTests {
    static let anchor = LocalDay.day("2026-10-10")

    func window(endingAt today: String, value: Int) -> [DailyPoint] {
        ActivityWindow.days(endingAt: .day(today)).map { DailyPoint(day: $0, value: value) }
    }

    /// Up to four earlier recordings, of any provider, on days around the anchor.
    func randomHistory(_ gen: inout Gen) -> UsageHistory {
        var history = UsageHistory()
        for _ in 0..<gen.int(in: 0...4) {
            let today = gen.localDay(around: Self.anchor)
            let provider = gen.providerID(from: ProviderID.allCases)
            history.record(randomPoints(&gen, around: today), for: provider, today: today)
        }
        return history
    }

    /// Up to ten days around `today`, some past the retention and some after `today`, with any token count.
    func randomPoints(_ gen: inout Gen, around today: LocalDay) -> [DailyPoint] {
        (0..<gen.int(in: 0...10)).map { _ in DailyPoint(day: gen.localDay(around: today), value: gen.int(in: 0...100_000_000)) }
    }

    /// Every stored day, read through the persisted format: provider, then day.
    func storedDays(of history: UsageHistory) throws -> [ProviderID: [LocalDay: Int]] {
        try JSONDecoder().decode([ProviderID: [LocalDay: Int]].self, from: JSONEncoder().encode(history))
    }

    @Test("B-42 history rewrites the window's days and freezes older ones")
    func overwritesTheWindowAndFreezesOlderDays() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", value: 5), for: .claude, today: .day("2026-10-10"))
        history.record(window(endingAt: "2026-10-12", value: 9), for: .claude, today: .day("2026-10-12"))

        let points = history.points(for: .claude, endingAt: .day("2026-10-12"), count: 11)
        #expect(points.map(\.value) == [0, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9]) // 10-02 never existed; 10-03 and 10-04 are frozen
    }

    @Test("B-42 history prunes days past 35")
    func prunesToThirtyFiveDays() throws {
        var history = UsageHistory()
        history.record([DailyPoint(day: .day("2026-09-01"), value: 1)], for: .cursor, today: .day("2026-09-01"))
        history.record(window(endingAt: "2026-10-10", value: 2), for: .cursor, today: .day("2026-10-10"))

        let json = String(decoding: try JSONEncoder().encode(history), as: UTF8.self)
        #expect(!json.contains("2026-09-01"))
        #expect(history.points(for: .cursor, endingAt: .day("2026-10-10"), count: 41).first?.value == 0)
    }

    @Test("B-42 each provider has its own history")
    func providersAreIndependent() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", value: 7), for: .claude, today: .day("2026-10-10"))
        #expect(history.points(for: .cursor, endingAt: .day("2026-10-10")).allSatisfy { $0.value == 0 })
        #expect(history.points(for: .claude, endingAt: .day("2026-10-10")).count == 7)
    }

    @Test("B-42 pruning is per provider: a provider's days stay until it records again")
    func pruningIsPerProvider() {
        var history = UsageHistory()
        history.record([DailyPoint(day: .day("2026-09-01"), value: 3)], for: .claude, today: .day("2026-09-01"))
        history.record(window(endingAt: "2026-10-10", value: 2), for: .cursor, today: .day("2026-10-10"))
        #expect(history.points(for: .claude, endingAt: .day("2026-09-01"), count: 1).map(\.value) == [3])

        history.record(window(endingAt: "2026-10-10", value: 2), for: .claude, today: .day("2026-10-10"))
        #expect(history.points(for: .claude, endingAt: .day("2026-09-01"), count: 1).map(\.value) == [0])
    }

    @Test("B-43 the week chart reads the 7 days ending today, zero-filled")
    func weekChartReadsTheSevenDaysEndingToday() {
        var history = UsageHistory()
        let recorded = [DailyPoint(day: .day("2026-10-08"), value: 400), DailyPoint(day: .day("2026-10-10"), value: 9)]
        history.record(recorded, for: .claude, today: .day("2026-10-10"))

        let week = history.points(for: .claude, endingAt: .day("2026-10-10"))
        #expect(week.map(\.day.iso) == ["2026-10-04", "2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09", "2026-10-10"])
        #expect(week.map(\.value) == [0, 0, 0, 0, 400, 0, 9])
    }

    @Test("history.json keeps its shape")
    func historyFileKeepsItsShape() throws {
        let history = try Fixture.persisted(UsageHistory.self, from: "history.json")
        #expect(history.points(for: .claude, endingAt: .day("2026-10-10"), count: 4).map(\.value) == [0, 18_420_000, 25_310_000, 1_250_000])
        #expect(history.points(for: .cursor, endingAt: .day("2026-10-10"), count: 3).map(\.value) == [0, 2_662_000, 29_200])
    }

    @Test func encodesAsProviderThenDay() throws {
        var history = UsageHistory()
        history.record([DailyPoint(day: .day("2026-10-10"), value: 1_250_000)], for: .claude, today: .day("2026-10-10"))
        #expect(String(decoding: try JSONEncoder().encode(history), as: UTF8.self) == #"{"claude":{"2026-10-10":1250000}}"#)
        #expect(try JSONDecoder().decode(UsageHistory.self, from: JSONEncoder().encode(history)) == history)
    }

    @Test(arguments: Gen.seeds(200))
    func recordingTwiceIsRecordingOnce(seed: UInt64) {
        var gen = Gen(seed: seed)
        var once = randomHistory(&gen)
        let today = gen.localDay(around: Self.anchor)
        let provider = gen.providerID(from: ProviderID.allCases)
        let points = randomPoints(&gen, around: today)
        once.record(points, for: provider, today: today)
        var twice = once
        twice.record(points, for: provider, today: today)
        #expect(twice == once, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func recordingKeepsNoDayPastTheRetention(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = randomHistory(&gen)
        let today = gen.localDay(around: Self.anchor)
        let provider = gen.providerID(from: ProviderID.allCases)
        history.record(randomPoints(&gen, around: today), for: provider, today: today)

        let oldestKept = today.advanced(by: 1 - UsageHistory.retentionDays)
        let days = try storedDays(of: history)[provider, default: [:]].keys
        #expect(days.allSatisfy { $0 >= oldestKept }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func recordingLeavesOtherProvidersUntouched(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = randomHistory(&gen)
        let before = try storedDays(of: history)
        let today = gen.localDay(around: Self.anchor)
        let provider = gen.providerID(from: ProviderID.allCases)
        history.record(randomPoints(&gen, around: today), for: provider, today: today)

        let after = try storedDays(of: history)
        for other in ProviderID.allCases where other != provider {
            #expect(after[other] == before[other], "seed \(seed)")
        }
    }
}
