import BurnieDomain
import BurnieTestSupport
import Foundation
import Testing
@testable import BurnieApplication

struct SchedulingTests {
    static let triggers: [RefreshTrigger] = [.timer, .popoverOpened, .manual, .wake, .networkRestored, .activityChanged]
    static let policies = [TestProviders.alphaLimitsPolicy, TestProviders.alphaActivityPolicy, TestProviders.betaLimitsPolicy, TestProviders.betaActivityPolicy]

    /// A job of any policy, maybe running, maybe in a backoff, maybe waiting for the user, last run around `now`.
    func job(_ gen: inout Gen, now: Date) -> JobState {
        var job = JobState(part: gen.coinFlip() ? .limits : .activity, policy: gen.element(of: Self.policies))
        job.running = gen.maybe { RunID(value: $0.int(in: 0...9)) }
        job.lastRun = gen.maybe { $0.date(around: now) }
        if gen.coinFlip() {
            job.backoff.recordRateLimit(retryAt: gen.maybe { $0.date(around: now) }, now: gen.date(around: now))
        }
        for _ in 0..<gen.int(in: 0...3) {
            job.idle.record(Result<Part, ProviderIssue>.failure(.notFound))
        }
        return job
    }

    @Test(arguments: Gen.seeds(200))
    func aRunningJobNeverRunsAgain(seed: UInt64) {
        var gen = Gen(seed: seed)
        let now = gen.date()
        var job = job(&gen, now: now)
        job.running = RunID(value: 0)
        let trigger = gen.element(of: Self.triggers)
        #expect(!Scheduling.canRun(job, trigger: trigger, isOnline: gen.coinFlip(), now: now), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func nothingRunsBeforeRetryAt(seed: UInt64) {
        var gen = Gen(seed: seed)
        let now = gen.date()
        var job = job(&gen, now: now)
        job.backoff.recordRateLimit(retryAt: now.addingTimeInterval(TimeInterval(gen.int(in: 1...3_600))), now: now)
        #expect(!Scheduling.canRun(job, trigger: gen.element(of: Self.triggers), isOnline: true, now: now), "seed \(seed)")
    }

    @Test(arguments: Gen.seeds(200))
    func offlineNothingThatNeedsTheNetworkRuns(seed: UInt64) {
        var gen = Gen(seed: seed)
        let now = gen.date()
        let job = job(&gen, now: now)
        if job.policy.needsNetwork {
            #expect(!Scheduling.canRun(job, trigger: gen.element(of: Self.triggers), isOnline: false, now: now), "seed \(seed)")
        }
    }

    @Test(arguments: Gen.seeds(200))
    func theDelayIsNeverNegativeAndKeepsToItsBounds(seed: UInt64) {
        var gen = Gen(seed: seed)
        let now = gen.date()
        let job = job(&gen, now: now)
        let jitter = Double.random(in: -1...1, using: &gen)
        let delay = Scheduling.delay(for: job, now: now, jitter: jitter)
        #expect(delay >= 0, "seed \(seed)")
        if let retryAt = job.backoff.retryAt {
            #expect(delay == max(retryAt.timeIntervalSince(now), 0), "seed \(seed)")
        } else {
            let interval = job.idle.stretch(job.policy.interval)
            #expect((interval - job.policy.jitter...interval + job.policy.jitter).contains(delay), "seed \(seed)")
            #expect(Scheduling.delay(for: job, now: now, jitter: 0) == interval, "seed \(seed)")
        }
    }

    @Test("B-35 the jitter sample moves the interval by up to the policy's jitter, either way")
    func jitterMovesTheInterval() {
        let job = JobState(part: .limits, policy: TestProviders.alphaLimitsPolicy)
        let now = ReducerHarness.start
        #expect(Scheduling.delay(for: job, now: now, jitter: -1) == 270)
        #expect(Scheduling.delay(for: job, now: now, jitter: 0) == 300)
        #expect(Scheduling.delay(for: job, now: now, jitter: 1) == 330)
    }
}
