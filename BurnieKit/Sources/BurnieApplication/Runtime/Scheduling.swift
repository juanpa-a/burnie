import BurnieDomain
import Foundation

/// The pure decisions over a job: whether a trigger runs it now, and how long until its next timer.
enum Scheduling {
    /// Not running (B-32), not before its backoff's `retryAt` (B-33), online or needing no network (B-34), with its
    /// breaker reset unless Refresh asks (B-81), and the policy accepts the trigger (B-31).
    static func canRun(_ job: JobState, trigger: RefreshTrigger, isOnline: Bool, now: Date) -> Bool {
        job.running == nil
            && job.backoff.allowsRequest(at: now)
            && (isOnline || !job.policy.needsNetwork)
            && (!job.breaker.isTripped || trigger == .manual)
            && job.policy.shouldRun(for: trigger, lastRun: job.lastRun, now: now)
    }

    /// Until `retryAt` during a backoff, else the interval, stretched while the job waits for the user, moved by
    /// `jitter`, a sample in -1…1 the interpreter draws, times the policy's jitter (B-35). Never negative.
    static func delay(for job: JobState, now: Date, jitter: Double) -> TimeInterval {
        if let retryAt = job.backoff.retryAt {
            return max(retryAt.timeIntervalSince(now), 0)
        }
        let sample = min(max(jitter, -1), 1)
        return max(job.idle.stretch(job.policy.interval) + job.policy.jitter * sample, 0)
    }
}
