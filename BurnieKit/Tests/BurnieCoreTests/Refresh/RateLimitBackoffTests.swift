import Foundation
import Testing
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
}
