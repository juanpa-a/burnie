import Foundation
import BurnieCore

/// Decides when each source refreshes: one timer per source with jitter, one fetch at a time per source,
/// backoff on 429, and outside triggers (opening the popover, wake, network, logs, the Refresh button).
actor RefreshScheduler {
    typealias Refresh = @Sendable (RefreshJob) async -> ProviderIssue?

    private struct JobState {
        var timer: Task<Void, Never>?
        var isRunning = false
        var lastRun: Date?
        var backoff = RateLimitBackoff()
    }

    private let clock: Clock
    private let refresh: Refresh
    private var jobs: [RefreshJob: JobState] = [:]
    private var isOnline = true

    init(clock: Clock, refresh: @escaping Refresh) {
        self.clock = clock
        self.refresh = refresh
    }

    /// Activates the sources of `providers`, deactivates the rest, and immediately starts a refresh of the newly
    /// activated ones without waiting for it: a later deactivation doesn't have to wait on the network.
    func setActive(_ providers: Set<ProviderID>) {
        for job in jobs.keys where !providers.contains(job.provider) {
            jobs.removeValue(forKey: job)?.timer?.cancel()
        }
        let added = providers.flatMap { provider in UsageSource.allCases.map { RefreshJob(provider: provider, source: $0) } }
            .filter { jobs[$0] == nil }
        for job in added {
            jobs[job] = JobState()
        }
        Task { await run(added, for: .manual) }
    }

    /// Refreshes the active sources that `trigger` warrants and returns when they finish.
    func trigger(_ trigger: RefreshTrigger, for providers: Set<ProviderID> = Set(ProviderID.allCases), source: UsageSource? = nil) async {
        let candidates = jobs.keys.filter { providers.contains($0.provider) && (source == nil || $0.source == source) }
        await run(candidates, for: trigger)
    }

    func setOnline(_ isOnline: Bool) async {
        let wasOffline = !self.isOnline
        self.isOnline = isOnline
        if isOnline && wasOffline {
            await trigger(.networkRestored)
        }
    }

    private func run(_ candidates: [RefreshJob], for trigger: RefreshTrigger) async {
        let now = clock.now
        let eligible = candidates.filter { canRun($0, for: trigger, now: now) }
        await withTaskGroup(of: Void.self) { group in
            for job in eligible {
                group.addTask { await self.run(job) }
            }
        }
    }

    private func canRun(_ job: RefreshJob, for trigger: RefreshTrigger, now: Date) -> Bool {
        guard let state = jobs[job], !state.isRunning, state.backoff.allowsRequest(at: now) else { return false }
        let policy = RefreshPolicy.standard(for: job)
        guard isOnline || !policy.needsNetwork else { return false }
        return policy.shouldRun(for: trigger, lastRun: state.lastRun, now: now)
    }

    private func run(_ job: RefreshJob) async {
        // Another trigger may have started it between the filter and this point.
        guard jobs[job]?.isRunning == false else { return }
        jobs[job]?.isRunning = true
        jobs[job]?.timer?.cancel()

        let issue = await refresh(job)

        guard var state = jobs[job] else { return } // deactivated while it was running
        state.isRunning = false
        state.lastRun = clock.now
        if case .rateLimited(let retryAt) = issue {
            state.backoff.recordRateLimit(retryAt: retryAt, now: clock.now)
        } else {
            state.backoff.reset()
        }
        state.timer = timer(for: job, after: delay(for: job, backoff: state.backoff))
        jobs[job] = state
    }

    private func delay(for job: RefreshJob, backoff: RateLimitBackoff) -> TimeInterval {
        if let retryAt = backoff.retryAt {
            return max(retryAt.timeIntervalSince(clock.now), 0)
        }
        let policy = RefreshPolicy.standard(for: job)
        return policy.interval + .random(in: -policy.jitter...policy.jitter)
    }

    private func timer(for job: RefreshJob, after delay: TimeInterval) -> Task<Void, Never> {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self.timerFired(for: job)
        }
    }

    /// The timer lets go of itself before running: if `run` cancelled it, it would also cancel the request in flight.
    private func timerFired(for job: RefreshJob) async {
        jobs[job]?.timer = nil
        await run([job], for: .timer)
    }
}
