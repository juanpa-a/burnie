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
}
