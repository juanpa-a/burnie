import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ActivityPartTests {
    static let today = LocalDay.day("2026-10-10")
    static let part = ActivityPart(tokens: [today: Tokens(1_800_000)])

    @Test func todaysUsageIsTodaysTokens() {
        #expect(Self.part.usage(on: Self.today) == TodayUsage(tokens: Tokens(1_800_000)))
    }

    @Test("B-42 a day the activity doesn't mention reads zero tokens")
    func anUnmentionedDayIsZero() {
        #expect(Self.part.usage(on: Self.today.advanced(by: 1)) == TodayUsage(tokens: .zero))
    }
}
