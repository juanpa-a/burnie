import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct ActivityPartTests {
    static let today = LocalDay.day("2026-10-10")
    static let part = ActivityPart(tokens: [today: Tokens(1_800_000)], spent: [today: Cents(1_240)])

    @Test("B-7 today's usage reads money when the plan measures money and today's spend is known")
    func moneyWithSpend() {
        #expect(Self.part.usage(on: Self.today, in: .money) == .money(Cents(1_240)))
    }

    @Test("B-7 today's usage reads tokens without today's spend, or for a plan that measures tokens")
    func tokensOtherwise() {
        #expect(ActivityPart(tokens: [Self.today: Tokens(1_800_000)]).usage(on: Self.today, in: .money) == .tokens(Tokens(1_800_000)))
        #expect(Self.part.usage(on: Self.today, in: .tokens) == .tokens(Tokens(1_800_000)))
    }

    @Test("B-42 a day the activity doesn't mention reads zero tokens")
    func anUnmentionedDayIsZero() {
        #expect(Self.part.usage(on: Self.today.advanced(by: 1), in: .tokens) == .tokens(.zero))
    }
}
