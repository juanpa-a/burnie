import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct UsageHistoryTests {
    /// The same tokens on every day of the activity window ending `today`.
    func window(endingAt today: String, tokens: Int) -> [LocalDay: Tokens] {
        Dictionary(uniqueKeysWithValues: ActivityWindow.days(endingAt: .day(today)).map { ($0, Tokens(tokens)) })
    }

    func tokens(_ history: UsageHistory, for provider: ProviderID, endingAt today: String, count: Int) -> [Int] {
        history.points(for: provider, endingAt: .day(today), count: count).map(\.tokens.count)
    }

    /// Up to four earlier recordings, of either provider, on days around the reference.
    func randomHistory(_ gen: inout Gen) -> UsageHistory {
        var history = UsageHistory()
        for _ in 0..<gen.int(in: 0...4) {
            let today = gen.localDay()
            history.record(gen.activityPart(around: today).tokens, for: gen.providerID(), today: today)
        }
        return history
    }

    /// Every stored day, read through the persisted format: provider, then day.
    func storedDays(of history: UsageHistory) throws -> [ProviderID: [LocalDay: Tokens]] {
        try JSONDecoder().decode([ProviderID: [LocalDay: Tokens]].self, from: JSONEncoder().encode(history))
    }

    @Test("B-42 history rewrites the window's days and freezes older ones")
    func rewritesTheWindowAndFreezesOlderDays() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", tokens: 5), for: .alpha, today: .day("2026-10-10"))
        history.record(window(endingAt: "2026-10-12", tokens: 9), for: .alpha, today: .day("2026-10-12"))
        // 10-02 never existed; 10-03 and 10-04 are frozen.
        #expect(tokens(history, for: .alpha, endingAt: "2026-10-12", count: 11) == [0, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9])
    }

    @Test("B-42 a window day the activity doesn't mention is rewritten as 0")
    func unmentionedWindowDaysBecomeZero() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", tokens: 5), for: .alpha, today: .day("2026-10-10"))
        history.record([.day("2026-10-10"): Tokens(9)], for: .alpha, today: .day("2026-10-10"))
        #expect(tokens(history, for: .alpha, endingAt: "2026-10-10", count: 3) == [0, 0, 9])
    }

    @Test("B-42 history prunes days past 35")
    func prunesPastTheRetention() throws {
        var history = UsageHistory()
        history.record([.day("2026-09-01"): Tokens(1)], for: .beta, today: .day("2026-09-01"))
        history.record(window(endingAt: "2026-10-10", tokens: 2), for: .beta, today: .day("2026-10-10"))
        #expect(try storedDays(of: history)[.beta]?[.day("2026-09-01")] == nil)
        #expect(tokens(history, for: .beta, endingAt: "2026-10-10", count: 41).first == 0)
    }

    @Test("B-42 each provider has its own history")
    func providersAreIndependent() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", tokens: 7), for: .alpha, today: .day("2026-10-10"))
        #expect(tokens(history, for: .beta, endingAt: "2026-10-10", count: 7).allSatisfy { $0 == 0 })
        #expect(tokens(history, for: .alpha, endingAt: "2026-10-10", count: 7).count == 7)
    }

    @Test("B-42 pruning is per provider: a provider's days stay until it records again")
    func pruningIsPerProvider() {
        var history = UsageHistory()
        history.record([.day("2026-09-01"): Tokens(3)], for: .alpha, today: .day("2026-09-01"))
        history.record(window(endingAt: "2026-10-10", tokens: 2), for: .beta, today: .day("2026-10-10"))
        #expect(tokens(history, for: .alpha, endingAt: "2026-09-01", count: 1) == [3])

        history.record(window(endingAt: "2026-10-10", tokens: 2), for: .alpha, today: .day("2026-10-10"))
        #expect(tokens(history, for: .alpha, endingAt: "2026-09-01", count: 1) == [0])
    }

    @Test("B-79 a total adds up the days from the first through the last, 0 for the days without data")
    func totalsTheDaysInARange() {
        var history = UsageHistory()
        history.record([.day("2026-10-04"): Tokens(1), .day("2026-10-08"): Tokens(20), .day("2026-10-10"): Tokens(300)], for: .alpha, today: .day("2026-10-10"))
        #expect(history.total(for: .alpha, from: .day("2026-10-01"), through: .day("2026-10-10")) == Tokens(321))
        #expect(history.total(for: .alpha, from: .day("2026-10-05"), through: .day("2026-10-08")) == Tokens(20))
        #expect(history.total(for: .alpha, from: .day("2026-10-09"), through: .day("2026-10-08")) == .zero)
        #expect(history.total(for: .beta, from: .day("2026-10-01"), through: .day("2026-10-10")) == .zero)
    }

    @Test("B-79 history is recorded since the first day of its unbroken run, which a gap cuts")
    func recordedSinceStartsAfterTheLatestGap() {
        var history = UsageHistory()
        #expect(history.recordedSince(for: .alpha) == nil)

        history.record(window(endingAt: "2026-10-10", tokens: 5), for: .alpha, today: .day("2026-10-10"))
        #expect(history.recordedSince(for: .alpha) == .day("2026-10-03"))

        history.record(window(endingAt: "2026-10-12", tokens: 5), for: .alpha, today: .day("2026-10-12"))
        #expect(history.recordedSince(for: .alpha) == .day("2026-10-03"))

        // Nine days later the window no longer reaches the 12th, so the 13th is missing.
        history.record(window(endingAt: "2026-10-21", tokens: 5), for: .alpha, today: .day("2026-10-21"))
        #expect(history.recordedSince(for: .alpha) == .day("2026-10-14"))
        #expect(history.recordedSince(for: .beta) == nil)
    }

    @Test("B-79 a cycle total counts from the day the cycle starts, or from the day the history is recorded since")
    func cycleTotalsCountTheRecordedDaysOfTheCycle() {
        var history = UsageHistory()
        // Unbroken from September 25 through today.
        history.record([.day("2026-09-26"): Tokens(1), .day("2026-10-02"): Tokens(20)], for: .alpha, today: .day("2026-10-02"))
        history.record([.day("2026-10-08"): Tokens(300), .day("2026-10-10"): Tokens(4_000)], for: .alpha, today: .day("2026-10-10"))
        let today = LocalDay.day("2026-10-10")
        #expect(history.cycleTotal(for: .alpha, startingOn: .day("2026-10-02"), today: today) == Tokens(4_320))
        #expect(history.cycleTotal(for: .alpha, startingOn: .day("2026-09-10"), today: today) == Tokens(4_321))
        #expect(history.cycleTotal(for: .alpha, startingOn: today.advanced(by: 1), today: today) == nil)
        #expect(history.cycleTotal(for: .beta, startingOn: .day("2026-10-02"), today: today) == nil)
    }

    @Test func encodesAsProviderThenDay() throws {
        var history = UsageHistory()
        history.record([.day("2026-10-10"): Tokens(1_250_000)], for: .alpha, today: .day("2026-10-10"))
        let json = String(decoding: try JSONEncoder.persistence.encode(history), as: UTF8.self)
        #expect(json.hasPrefix(#"{"alpha":{"#))
        #expect(json.contains(#""2026-10-10":1250000"#))
    }

    @Test(arguments: Gen.seeds(200))
    func recordingTwiceIsRecordingOnce(seed: UInt64) {
        var gen = Gen(seed: seed)
        var once = randomHistory(&gen)
        let today = gen.localDay()
        let provider = gen.providerID()
        let tokens = gen.activityPart(around: today).tokens
        once.record(tokens, for: provider, today: today)
        var twice = once
        twice.record(tokens, for: provider, today: today)
        #expect(twice == once, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func recordingKeepsNoDayPastTheRetention(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = randomHistory(&gen)
        let today = gen.localDay()
        let provider = gen.providerID()
        history.record(gen.activityPart(around: today).tokens, for: provider, today: today)

        let oldestKept = today.advanced(by: 1 - UsageHistory.retentionDays)
        let days = try storedDays(of: history)[provider, default: [:]].keys
        #expect(days.allSatisfy { $0 >= oldestKept }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func recordingWritesEveryDayOfTheWindow(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = randomHistory(&gen)
        let today = gen.localDay()
        let provider = gen.providerID()
        let tokens = gen.activityPart(around: today).tokens
        history.record(tokens, for: provider, today: today)

        let stored = try storedDays(of: history)[provider, default: [:]]
        for day in ActivityWindow.days(endingAt: today) {
            #expect(stored[day] == tokens[day, default: .zero], "seed \(seed)")
        }
    }

    @Test(arguments: Gen.seeds(200))
    func recordingLeavesOtherProvidersUntouched(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var history = randomHistory(&gen)
        let before = try storedDays(of: history)
        let today = gen.localDay()
        let provider = gen.providerID()
        history.record(gen.activityPart(around: today).tokens, for: provider, today: today)

        let after = try storedDays(of: history)
        for other in [ProviderID.alpha, .beta] where other != provider {
            #expect(after[other] == before[other], "seed \(seed)")
        }
    }

    @Test(arguments: Gen.seeds(200))
    func pointsAreConsecutiveDaysEndingToday(seed: UInt64) {
        var gen = Gen(seed: seed)
        let history = randomHistory(&gen)
        let today = gen.localDay()
        let count = gen.int(in: -3...40)
        let points = history.points(for: gen.providerID(), endingAt: today, count: count)
        #expect(points.count == max(count, 0), "seed \(seed)")
        #expect(points.last.map { $0.day == today } ?? true, "seed \(seed)")
        #expect(zip(points, points.dropFirst()).allSatisfy { $0.day.advanced(by: 1) == $1.day }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func totalsSplitAtAnyDay(seed: UInt64) {
        var gen = Gen(seed: seed)
        let history = randomHistory(&gen)
        let provider = gen.providerID()
        let first = gen.localDay()
        let middle = first.advanced(by: gen.int(in: 0...20))
        let last = middle.advanced(by: gen.int(in: 1...20))
        let whole = history.total(for: provider, from: first, through: last)
        #expect(whole == history.total(for: provider, from: first, through: middle) + history.total(for: provider, from: middle.advanced(by: 1), through: last), "seed \(seed)")
        #expect(history.total(for: provider, from: last, through: first) == .zero, "seed \(seed)")
        #expect(history.total(for: provider, from: first, through: first) == history.points(for: provider, endingAt: first, count: 1)[0].tokens, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func recordedSinceIsAnUnbrokenRunToTheLatestDay(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        let history = randomHistory(&gen)
        let provider = gen.providerID()
        let stored = try storedDays(of: history)[provider, default: [:]]
        guard let since = history.recordedSince(for: provider), let latest = stored.keys.max() else {
            #expect(stored.isEmpty, "seed \(seed)")
            return
        }
        #expect((since...latest).allSatisfy { stored[$0] != nil }, "seed \(seed)")
        #expect(stored[since.advanced(by: -1)] == nil, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func cycleTotalsCountFromTheLaterOfTheCycleAndTheHistory(seed: UInt64) {
        var gen = Gen(seed: seed)
        let history = randomHistory(&gen)
        let provider = gen.providerID()
        let cycleStart = gen.localDay()
        let today = gen.localDay()
        let first = history.recordedSince(for: provider).map { max($0, cycleStart) }
        guard let first, first <= today else {
            #expect(history.cycleTotal(for: provider, startingOn: cycleStart, today: today) == nil, "seed \(seed)")
            return
        }
        #expect(history.cycleTotal(for: provider, startingOn: cycleStart, today: today) == history.total(for: provider, from: first, through: today), "seed \(seed)")
    }
}
