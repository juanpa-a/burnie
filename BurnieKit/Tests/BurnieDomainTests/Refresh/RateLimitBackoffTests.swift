import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieDomain

struct RateLimitBackoffTests {
    let now = Date.iso("2026-10-10T20:00:00Z")

    @Test("B-33 nothing is requested before the server's Retry-After")
    func honorsTheServerRetryAfter() {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: now.addingTimeInterval(90), now: now)
        #expect(!backoff.allowsRequest(at: now.addingTimeInterval(89)))
        #expect(backoff.allowsRequest(at: now.addingTimeInterval(90)))
    }

    @Test("B-33 without Retry-After the wait doubles from 1 minute up to 45")
    func doublesFromOneMinuteUpToFortyFive() {
        var backoff = RateLimitBackoff()
        var waits: [TimeInterval] = []
        for _ in 0..<8 {
            backoff.recordRateLimit(retryAt: nil, now: now)
            waits.append(backoff.retryAt!.timeIntervalSince(now) / 60)
        }
        #expect(waits == [1, 2, 4, 8, 16, 32, 45, 45])
    }

    @Test("B-33 a Retry-After of 0, in the past, or not finite waits the step, never retrying at once", arguments: [
        0, -600, .infinity, -.infinity, .nan,
    ] as [TimeInterval])
    func retryAfterShorterThanTheStepWaitsTheStep(serverWait: TimeInterval) {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: now.addingTimeInterval(serverWait), now: now)
        #expect(backoff.retryAt == now.addingTimeInterval(60))
    }

    @Test("B-33 a Retry-After past 45 minutes waits 45 minutes")
    func retryAfterPastTheLongestWaitIsCapped() {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: now.addingTimeInterval(24 * 60 * 60), now: now)
        #expect(backoff.retryAt == now.addingTimeInterval(45 * 60))
    }

    @Test("B-33 recording a 429 starts the wait, and recording any other outcome resets it")
    func recordingAnOutcome() {
        var backoff = RateLimitBackoff()
        backoff.record(Result<Int, ProviderIssue>.failure(.rateLimited(retryAt: nil)), now: now)
        #expect(backoff.retryAt == now.addingTimeInterval(60))
        backoff.record(Result<Int, ProviderIssue>.failure(.offline), now: now)
        #expect(backoff == RateLimitBackoff())
        backoff.record(Result<Int, ProviderIssue>.failure(.rateLimited(retryAt: nil)), now: now)
        backoff.record(Result<Int, ProviderIssue>.success(1), now: now)
        #expect(backoff == RateLimitBackoff())
    }

    @Test("B-33 any other outcome resets the wait")
    func resetClearsTheWait() {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: nil, now: now)
        backoff.recordRateLimit(retryAt: nil, now: now)
        backoff.reset()
        #expect(backoff.allowsRequest(at: now))
        backoff.recordRateLimit(retryAt: nil, now: now)
        #expect(backoff.retryAt == now.addingTimeInterval(60))
    }

    @Test(arguments: Gen.seeds(200))
    func waitsWithoutRetryAfterNeverShrinkAndStopAtFortyFiveMinutes(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var backoff = RateLimitBackoff()
        var waits: [TimeInterval] = []
        for _ in 0..<gen.int(in: 1...12) {
            let rateLimitedAt = gen.date(around: now)
            backoff.recordRateLimit(retryAt: nil, now: rateLimitedAt)
            let retryAt = try #require(backoff.retryAt, "seed \(seed)")
            waits.append(retryAt.timeIntervalSince(rateLimitedAt))
        }
        #expect(zip(waits, waits.dropFirst()).allSatisfy { $0 <= $1 }, "seed \(seed)")
        #expect(waits.allSatisfy { $0 <= 45 * 60 }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func theWaitStaysBetweenTheStepAndFortyFiveMinutes(seed: UInt64) throws {
        var gen = Gen(seed: seed)
        var backoff = RateLimitBackoff()
        let earlierRateLimits = gen.int(in: 0...12)
        for _ in 0..<earlierRateLimits {
            backoff.recordRateLimit(retryAt: nil, now: now)
        }
        // From an hour in the past to two hours ahead: before the step, inside the range, and past 45 minutes.
        let serverWait = TimeInterval(gen.int(in: -3_600...7_200))
        let serverDate = now.addingTimeInterval(serverWait)
        backoff.recordRateLimit(retryAt: serverDate, now: now)

        let step = TimeInterval(60 << min(earlierRateLimits, 6))
        let wait = try #require(backoff.retryAt, "seed \(seed)").timeIntervalSince(now)
        #expect(wait >= min(step, 45 * 60) && wait <= 45 * 60, "seed \(seed)")
        if serverWait >= step && serverWait <= 45 * 60 {
            #expect(backoff.retryAt == serverDate, "seed \(seed)")
        }
    }

    @Test(arguments: Gen.seeds(200))
    func resetReturnsToTheInitialValue(seed: UInt64) {
        var gen = Gen(seed: seed)
        var backoff = rateLimited(by: &gen)
        backoff.reset()
        #expect(backoff == RateLimitBackoff(), "seed \(seed)")
    }

    /// A backoff after up to 12 rate limits around `now`, each with or without a server date.
    func rateLimited(by gen: inout Gen) -> RateLimitBackoff {
        var backoff = RateLimitBackoff()
        for _ in 0..<gen.int(in: 0...12) {
            let serverDate = gen.coinFlip() ? gen.date(around: now) : nil
            backoff.recordRateLimit(retryAt: serverDate, now: gen.date(around: now))
        }
        return backoff
    }
}
