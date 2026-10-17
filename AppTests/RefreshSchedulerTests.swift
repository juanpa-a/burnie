import BurnieCore
import LegacyTestSupport
import Foundation
import Testing

/// When each task runs and when its timer fires, driven through the scheduler's API with a manual clock and sleeper.
/// Every wait is on a signal; should a change lose one, the time limit fails the test instead of hanging the run.
@Suite(.timeLimit(.minutes(1)))
struct RefreshSchedulerTests {
    /// The scheduler's refresh as the tests see it: it notes each job it's asked to run, holds runs behind `gate`
    /// while the test keeps it closed, and answers each job with the issue the test set for it, none by default.
    /// `lock` serializes `issues`, `runs` and `cancelled`, so the scheduler's tasks can share it.
    final class FakeRefresh: @unchecked Sendable {
        let gate = Gate()
        private let lock = NSLock()
        private var issues: [RefreshJob: ProviderIssue] = [:]
        private var runs: [RefreshJob] = []
        private var cancelled: [RefreshJob] = []

        /// The runs whose task was cancelled by the time they went past the gate.
        var cancelledRuns: [RefreshJob] { lock.withLock { cancelled } }

        func answer(_ job: RefreshJob, with issue: ProviderIssue?) {
            lock.withLock { issues[job] = issue }
        }

        /// The jobs that started a run since the last call.
        func takeRuns() -> Set<RefreshJob> {
            lock.withLock {
                defer { runs = [] }
                return Set(runs)
            }
        }

        func run(_ job: RefreshJob) async -> ProviderIssue? {
            lock.withLock { runs.append(job) }
            await gate.pass()
            return lock.withLock {
                if Task.isCancelled {
                    cancelled.append(job)
                }
                return issues[job]
            }
        }
    }

    static let claudeLimits = RefreshJob(provider: .claude, source: .limits)
    static let claudeActivity = RefreshJob(provider: .claude, source: .activity)
    static let cursorLimits = RefreshJob(provider: .cursor, source: .limits)
    static let cursorActivity = RefreshJob(provider: .cursor, source: .activity)

    let clock = ManualClock(now: .iso("2026-10-10T20:00:00Z"))
    let sleeper = ManualSleeper()
    let refresh = FakeRefresh()

    func makeScheduler() -> RefreshScheduler {
        RefreshScheduler(clock: clock, sleeper: sleeper) { [refresh] job in await refresh.run(job) }
    }

    /// A scheduler with `providers` active once their first runs are done, so every job has its timer armed.
    func activate(_ providers: Set<ProviderID>) async -> RefreshScheduler {
        let scheduler = makeScheduler()
        await scheduler.setActive(providers)
        await sleeper.nextSleeps(providers.count * UsageSource.allCases.count)
        _ = refresh.takeRuns()
        return scheduler
    }

    /// Moves the clock to the end of the pending timer that waits `wait`, fires it, and returns how long the timer
    /// its run arms waits.
    func fireTimer(waiting wait: TimeInterval) async -> TimeInterval {
        clock.advance(by: wait)
        sleeper.resume { $0 == wait }
        return await sleeper.nextSleeps(1)[0]
    }

    @Test("B-32 a job never runs twice at once")
    func singleFlight() async {
        let scheduler = makeScheduler()
        refresh.gate.close()
        await scheduler.setActive([.cursor])
        await refresh.gate.waitForArrivals(2)
        #expect(refresh.takeRuns() == [Self.cursorLimits, Self.cursorActivity])

        await scheduler.trigger(.manual)
        await scheduler.trigger(.wake)
        #expect(refresh.takeRuns().isEmpty)

        refresh.gate.open()
        await sleeper.nextSleeps(2)
        await scheduler.trigger(.manual)
        #expect(refresh.takeRuns() == [Self.cursorLimits, Self.cursorActivity])
    }

    @Test("B-33 after a 429, nothing is requested from that task before retryAt, not even with Refresh")
    func rateLimitedTaskWaitsForRetryAt() async {
        refresh.answer(Self.cursorLimits, with: .rateLimited(retryAt: clock.now.addingTimeInterval(120)))
        let scheduler = await activate([.cursor])
        refresh.answer(Self.cursorLimits, with: nil)

        clock.advance(by: 119)
        await scheduler.trigger(.manual)
        #expect(refresh.takeRuns() == [Self.cursorActivity])

        clock.advance(by: 1)
        await scheduler.trigger(.manual)
        #expect(refresh.takeRuns() == [Self.cursorLimits, Self.cursorActivity])
    }

    @Test("B-33 without Retry-After, each 429 in a row waits 1, 2, 4… minutes, up to 60")
    func backoffDoublesUpToAnHour() async {
        refresh.answer(Self.cursorLimits, with: .rateLimited(retryAt: nil))
        let scheduler = makeScheduler()
        await scheduler.setActive([.cursor])
        #expect(Set(await sleeper.nextSleeps(2)) == [60, CursorWaits.activity])

        var waits: [TimeInterval] = [60]
        for _ in 1...7 {
            waits.append(await fireTimer(waiting: waits[waits.count - 1]))
        }
        #expect(waits == [60, 120, 240, 480, 960, 1_920, 3_600, 3_600])
    }

    @Test("B-33 any other outcome resets the backoff", arguments: [nil, ProviderIssue.offline])
    func otherOutcomesResetTheBackoff(outcome: ProviderIssue?) async {
        refresh.answer(Self.cursorLimits, with: .rateLimited(retryAt: nil))
        let scheduler = await activate([.cursor])
        refresh.answer(Self.cursorLimits, with: outcome)
        #expect(CursorWaits.limits.contains(await fireTimer(waiting: 60)))

        refresh.answer(Self.cursorLimits, with: .rateLimited(retryAt: nil))
        await scheduler.trigger(.manual)
        #expect(Set(await sleeper.nextSleeps(2)) == [60, CursorWaits.activity])
    }

    @Test("B-34 the scheduler starts online, so the first runs include the tasks that need the network")
    func startsOnline() async {
        let scheduler = makeScheduler()
        await scheduler.setActive([.claude, .cursor])
        await sleeper.nextSleeps(4)
        #expect(refresh.takeRuns() == [Self.claudeLimits, Self.claudeActivity, Self.cursorLimits, Self.cursorActivity])
    }

    @Test("B-34 offline skips the tasks that need the network; Claude's activity, which doesn't, still runs")
    func offlineSkipsNetworkTasks() async {
        let scheduler = await activate([.claude, .cursor])
        await scheduler.setOnline(false)
        await scheduler.trigger(.manual)
        #expect(refresh.takeRuns() == [Self.claudeActivity])
    }

    @Test("B-35 without a backoff, the next timer waits the task's interval ± its jitter", arguments: [
        (ProviderID.claude, 300.0, 300.0),
        (ProviderID.cursor, 600.0, 1_800.0),
    ])
    func timerWaitsTheInterval(provider: ProviderID, limitsInterval: TimeInterval, activityWait: TimeInterval) async throws {
        let scheduler = makeScheduler()
        await scheduler.setActive([provider])
        var waits = await sleeper.nextSleeps(2)
        waits.remove(at: try #require(waits.firstIndex(of: activityWait)))
        let limitsWait = try #require(waits.first)
        #expect((limitsInterval - 30...limitsInterval + 30).contains(limitsWait))
        // A continuous sample lands exactly on the interval with negligible probability: a wait equal to it means no jitter.
        #expect(limitsWait != limitsInterval)
    }

    @Test("B-35 during a backoff, the next timer waits until retryAt")
    func timerWaitsForRetryAt() async {
        refresh.answer(Self.cursorLimits, with: .rateLimited(retryAt: clock.now.addingTimeInterval(90)))
        let scheduler = makeScheduler()
        await scheduler.setActive([.cursor])
        #expect(Set(await sleeper.nextSleeps(2)) == [90, CursorWaits.activity])
    }

    @Test("B-35 a timer that fires offline runs nothing; network restored runs its task once it's older than its interval")
    func offlineTimerWaitsForTheNetwork() async {
        let scheduler = await activate([.cursor])
        await scheduler.setOnline(false)
        // As late as Cursor's limits timer can fire: past its 10 min interval, short of its activity's 30.
        clock.advance(by: 630)
        await scheduler.timerFired(for: Self.cursorLimits)
        #expect(refresh.takeRuns().isEmpty)

        await scheduler.setOnline(true)
        #expect(refresh.takeRuns() == [Self.cursorLimits])
    }

    @Test("B-36 a timer lets go of itself before its run, so the run cancelling and re-arming it leaves the run alone")
    func firedTimerDoesNotCancelItsRun() async {
        _ = await activate([.cursor])
        sleeper.resume(where: CursorWaits.limits.contains)
        #expect(CursorWaits.limits.contains(await sleeper.nextSleeps(1)[0]))
        #expect(refresh.takeRuns() == [Self.cursorLimits])
        #expect(refresh.cancelledRuns.isEmpty)
    }

    @Test("B-37 activating providers starts their tasks without waiting for them")
    func activationDoesNotWait() async {
        let scheduler = makeScheduler()
        refresh.gate.close()
        await scheduler.setActive([.claude])
        await refresh.gate.waitForArrivals(2)
        #expect(refresh.takeRuns() == [Self.claudeLimits, Self.claudeActivity])
        refresh.gate.open()
    }

    @Test("B-37 deactivating a provider cancels its timers and stops its tasks")
    func deactivationCancelsTimers() async {
        let scheduler = await activate([.claude, .cursor])
        await scheduler.setActive([.cursor])
        #expect(sleeper.pending.count == 2)
        #expect(sleeper.pending.allSatisfy { $0 == CursorWaits.activity || CursorWaits.limits.contains($0) })

        await scheduler.trigger(.manual)
        #expect(refresh.takeRuns() == [Self.cursorLimits, Self.cursorActivity])
    }

    @Test("B-38 going offline and back online runs the tasks older than their interval")
    func networkRestoredRunsOverdueTasks() async {
        let scheduler = await activate([.claude, .cursor])
        await scheduler.setOnline(false)
        // Past Claude's 5 minutes, short of Cursor's 10 and 30.
        clock.advance(by: 400)
        await scheduler.setOnline(true)
        #expect(refresh.takeRuns() == [Self.claudeLimits, Self.claudeActivity])
    }

    @Test("B-38 a network report while already online runs nothing")
    func onlineWhileOnlineRunsNothing() async {
        let scheduler = await activate([.claude, .cursor])
        clock.advance(by: 4_000)
        await scheduler.setOnline(true)
        #expect(refresh.takeRuns().isEmpty)
    }
}
