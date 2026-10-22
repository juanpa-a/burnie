import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct IdleBackoffTests {
    static let waitsForTheUser: [Result<Int, ProviderIssue>] = [
        .failure(.notFound), .failure(.signInExpired), .failure(.specific(.alphaScope)),
    ]
    static let otherOutcomes: [Result<Int, ProviderIssue>] = [
        .success(1), .failure(.rateLimited(retryAt: nil)), .failure(.offline), .failure(.unexpectedResponse("HTTP 404")),
    ]

    @Test("B-35 each outcome in a row that waits for the user doubles the interval, up to 45 minutes", arguments: waitsForTheUser)
    func waitingForTheUserDoublesTheInterval(outcome: Result<Int, ProviderIssue>) {
        var idle = IdleBackoff()
        var intervals: [TimeInterval] = []
        for _ in 0..<6 {
            idle.record(outcome)
            intervals.append(idle.stretch(5 * 60) / 60)
        }
        #expect(intervals == [10, 20, 40, 45, 45, 45])
    }

    @Test("B-35 an interval of 45 minutes or longer stays as it is")
    func aLongIntervalIsNeverShortened() {
        var idle = IdleBackoff()
        idle.record(Result<Int, ProviderIssue>.failure(.notFound))
        #expect(idle.stretch(30 * 60) == 45 * 60)
        #expect(idle.stretch(60 * 60) == 60 * 60)
    }

    @Test("B-35 any other outcome resets the interval", arguments: otherOutcomes)
    func otherOutcomesReset(outcome: Result<Int, ProviderIssue>) {
        var idle = IdleBackoff()
        idle.record(Result<Int, ProviderIssue>.failure(.notFound))
        idle.record(outcome)
        #expect(idle == IdleBackoff())
        #expect(idle.stretch(5 * 60) == 5 * 60)
    }

    @Test(arguments: Gen.seeds(200))
    func theStretchStaysBetweenTheIntervalAndFortyFiveMinutesAndNeverShrinksWhileWaiting(seed: UInt64) {
        var gen = Gen(seed: seed)
        let interval = TimeInterval(gen.int(in: 1...7_200))
        var idle = IdleBackoff()
        var stretched: [TimeInterval] = []
        for _ in 0..<gen.int(in: 1...12) {
            idle.record(gen.element(of: Self.waitsForTheUser))
            stretched.append(idle.stretch(interval))
        }
        #expect(stretched.allSatisfy { $0 >= interval && $0 <= max(interval, 45 * 60) }, "seed \(seed)")
        #expect(zip(stretched, stretched.dropFirst()).allSatisfy { $0 <= $1 }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func anyOtherOutcomeReturnsToTheInterval(seed: UInt64) {
        var gen = Gen(seed: seed)
        let interval = TimeInterval(gen.int(in: 1...7_200))
        var idle = IdleBackoff()
        for _ in 0..<gen.int(in: 0...12) {
            idle.record(gen.element(of: Self.waitsForTheUser + Self.otherOutcomes))
        }
        idle.record(gen.element(of: Self.otherOutcomes))
        #expect(idle.stretch(interval) == interval, "seed \(seed)")
        #expect(idle == IdleBackoff(), "seed \(seed)")
    }
}
