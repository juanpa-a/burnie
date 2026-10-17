import Foundation
import Testing
import BurnieTestSupport
@testable import BurnieCore

struct RateLimitBackoffTests {
    let now = Date.iso("2026-10-10T20:00:00Z")

    @Test func honorsTheServerRetryAfter() {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: now.addingTimeInterval(90), now: now)
        #expect(!backoff.allowsRequest(at: now.addingTimeInterval(89)))
        #expect(backoff.allowsRequest(at: now.addingTimeInterval(90)))
    }

    @Test func doublesFromOneMinuteUpToAnHour() {
        var backoff = RateLimitBackoff()
        var waits: [TimeInterval] = []
        for _ in 0..<8 {
            backoff.recordRateLimit(retryAt: nil, now: now)
            waits.append(backoff.retryAt!.timeIntervalSince(now) / 60)
        }
        #expect(waits == [1, 2, 4, 8, 16, 32, 60, 60])
    }

    @Test func resetClearsTheWait() {
        var backoff = RateLimitBackoff()
        backoff.recordRateLimit(retryAt: nil, now: now)
        backoff.recordRateLimit(retryAt: nil, now: now)
        backoff.reset()
        #expect(backoff.allowsRequest(at: now))
        backoff.recordRateLimit(retryAt: nil, now: now)
        #expect(backoff.retryAt == now.addingTimeInterval(60))
    }

    @Test(arguments: Gen.seeds(200))
    func waitsWithoutRetryAfterNeverShrinkAndStopAtAnHour(seed: UInt64) throws {
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
        #expect(waits.allSatisfy { $0 <= 60 * 60 }, "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func retryAfterIsExactlyTheServerDate(seed: UInt64) {
        var gen = Gen(seed: seed)
        var backoff = rateLimited(by: &gen)
        let serverDate = gen.date(around: now)
        backoff.recordRateLimit(retryAt: serverDate, now: now)
        #expect(backoff.retryAt == serverDate, "seed \(seed)")
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
            let serverDate = gen.int(in: 0...1) == 0 ? gen.date(around: now) : nil
            backoff.recordRateLimit(retryAt: serverDate, now: gen.date(around: now))
        }
        return backoff
    }
}
