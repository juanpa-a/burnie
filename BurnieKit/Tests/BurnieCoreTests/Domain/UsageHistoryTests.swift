import Foundation
import Testing
@testable import BurnieCore

struct UsageHistoryTests {
    func window(endingAt today: String, value: Int) -> [DailyPoint] {
        ActivityWindow.days(endingAt: .day(today)).map { DailyPoint(day: $0, value: value) }
    }

    @Test func overwritesTheWindowAndFreezesOlderDays() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", value: 5), for: .claude, today: .day("2026-10-10"))
        history.record(window(endingAt: "2026-10-12", value: 9), for: .claude, today: .day("2026-10-12"))

        let points = history.points(for: .claude, endingAt: .day("2026-10-12"), count: 11)
        #expect(points.map(\.value) == [0, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9]) // 10-02 never existed; 10-03 and 10-04 are frozen
    }

    @Test func prunesToThirtyFiveDays() throws {
        var history = UsageHistory()
        history.record([DailyPoint(day: .day("2026-09-01"), value: 1)], for: .cursor, today: .day("2026-09-01"))
        history.record(window(endingAt: "2026-10-10", value: 2), for: .cursor, today: .day("2026-10-10"))

        let json = String(decoding: try JSONEncoder().encode(history), as: UTF8.self)
        #expect(!json.contains("2026-09-01"))
        #expect(history.points(for: .cursor, endingAt: .day("2026-10-10"), count: 41).first?.value == 0)
    }

    @Test func providersAreIndependent() {
        var history = UsageHistory()
        history.record(window(endingAt: "2026-10-10", value: 7), for: .claude, today: .day("2026-10-10"))
        #expect(history.points(for: .cursor, endingAt: .day("2026-10-10")).allSatisfy { $0.value == 0 })
        #expect(history.points(for: .claude, endingAt: .day("2026-10-10")).count == 7)
    }

    @Test func encodesAsProviderThenDay() throws {
        var history = UsageHistory()
        history.record([DailyPoint(day: .day("2026-10-10"), value: 1_250_000)], for: .claude, today: .day("2026-10-10"))
        #expect(String(decoding: try JSONEncoder().encode(history), as: UTF8.self) == #"{"claude":{"2026-10-10":1250000}}"#)
        #expect(try JSONDecoder().decode(UsageHistory.self, from: JSONEncoder().encode(history)) == history)
    }
}
