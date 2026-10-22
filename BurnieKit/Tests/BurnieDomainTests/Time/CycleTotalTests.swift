import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct CycleTotalTests {
    static let today = LocalDay.day("2026-10-10")

    /// Alpha recorded the window ending the 2nd and the one ending today: unbroken from September 25.
    static var history: UsageHistory {
        var history = UsageHistory()
        history.record([.day("2026-09-26"): Tokens(1), .day("2026-10-02"): Tokens(20)], for: .alpha, today: .day("2026-10-02"))
        history.record([.day("2026-10-08"): Tokens(300), today: Tokens(4_000)], for: .alpha, today: today)
        return history
    }

    @Test("B-79 a cycle total counts from the day the cycle starts through today")
    func countsFromTheCycleStart() {
        let total = CycleTotal.make(history: Self.history, provider: .alpha, cycleStart: .day("2026-10-02"), today: Self.today)
        #expect(total == CycleTotal(since: .day("2026-10-02"), tokens: Tokens(4_320)))
    }

    @Test("B-79 a cycle that starts before the history counts from the history's first day")
    func countsFromTheHistoryWhenTheCycleStartsBeforeIt() {
        let total = CycleTotal.make(history: Self.history, provider: .alpha, cycleStart: .day("2026-09-10"), today: Self.today)
        #expect(total == CycleTotal(since: .day("2026-09-25"), tokens: Tokens(4_321)))
    }

    @Test("B-79 without a recorded day of the cycle there's no total")
    func needsARecordedDayOfTheCycle() {
        #expect(CycleTotal.make(history: Self.history, provider: .beta, cycleStart: .day("2026-10-02"), today: Self.today) == nil)
        #expect(CycleTotal.make(history: Self.history, provider: .alpha, cycleStart: Self.today.advanced(by: 1), today: Self.today) == nil)
    }

    @Test(arguments: Gen.seeds(200))
    func countsTheRecordedDaysOfTheCycle(seed: UInt64) {
        var gen = Gen(seed: seed)
        var history = UsageHistory()
        for _ in 0..<gen.int(in: 0...4) {
            let day = gen.localDay()
            history.record(gen.activityPart(around: day).tokens, for: gen.providerID(), today: day)
        }
        let provider = gen.providerID()
        let cycleStart = gen.localDay()
        let today = gen.localDay()
        guard let total = CycleTotal.make(history: history, provider: provider, cycleStart: cycleStart, today: today) else {
            #expect(history.recordedSince(for: provider).map { max($0, cycleStart) > today } ?? true, "seed \(seed)")
            return
        }
        #expect(total.since == max(cycleStart, history.recordedSince(for: provider) ?? cycleStart), "seed \(seed)")
        #expect(total.since <= today, "seed \(seed)")
        #expect(total.tokens == history.total(for: provider, from: total.since, through: today), "seed \(seed)")
    }
}
