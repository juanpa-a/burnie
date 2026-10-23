import BurnieDomain
import Foundation

extension RuntimeState {
    /// Both open signals arrive together, so one within this of the last one is ignored (B-39).
    static let popoverDebounce: TimeInterval = 1

    /// Opening the popover refreshes what's stale, and its refresh shows the spinner (B-39, B-59).
    mutating func openPopover(_ request: RequestID, now: Date) -> [Effect] {
        if let lastPopoverOpen, now.timeIntervalSince(lastPopoverOpen) < Self.popoverDebounce { return [] }
        lastPopoverOpen = now
        open(request)
        return startRuns(of: enabledJobKeys, for: .popoverOpened, request: request, now: now) + closeIfDone(request)
    }

    /// The Refresh button: every enabled job regardless of age, except during a backoff (B-33).
    mutating func refresh(for request: RequestID, now: Date) -> [Effect] {
        open(request)
        return startRuns(of: enabledJobKeys, for: .manual, request: request, now: now) + closeIfDone(request)
    }

    /// A run finished. Its requests let go of it whatever happens; its outcome counts only if the run is still its
    /// job's, so a refresh that finishes after its provider was turned off, or off and on, is dropped (B-51).
    mutating func finish(_ key: JobKey, run: RunID, outcome: Result<Part, ProviderIssue>, jitter: Double, now: Date) -> [Effect] {
        let finishedRequests = release(run)
        guard var job = jobs[key], job.running == run else { return finishedRequests }
        job.running = nil
        job.lastRun = now
        job.backoff.record(outcome, now: now)
        job.idle.record(outcome)
        job.breaker.record(outcome)
        jobs[key] = job
        return show(outcome, of: job.part, for: key.provider, now: now)
            + armTimer(of: key, jitter: jitter, now: now)
            + finishedRequests
    }

    /// A timer that was cancelled or replaced while its event was on its way is ignored. Otherwise it lets go of the
    /// job, and runs it if it can; if it can't (offline), no timer is armed until another trigger runs the job (B-35).
    mutating func fire(_ timer: TimerID, of key: JobKey, now: Date) -> [Effect] {
        guard jobs[key]?.timer == timer else { return [] }
        jobs[key]?.timer = nil
        return startRun(of: key, for: .timer, request: nil, now: now)
    }

    /// Going from offline to online runs every job older than its interval, and arms the timer of every other job left
    /// with neither a run nor a timer, so none stays idle (B-35, B-38).
    mutating func changeNetwork(isOnline: Bool, jitter: Double, now: Date) -> [Effect] {
        let isRestored = isOnline && !self.isOnline
        self.isOnline = isOnline
        guard isRestored else { return [] }
        return enabledJobKeys.flatMap { key in
            let started = startRun(of: key, for: .networkRestored, request: nil, now: now)
            guard started.isEmpty, let job = jobs[key], job.running == nil, job.timer == nil else { return started }
            return armTimer(of: key, jitter: jitter, now: now)
        }
    }

    /// Records the outcome, composes the provider's snapshot and shows it: a snapshot is merged over the shown one and
    /// saved (B-11, B-17, B-19); a total failure shows the shown snapshot with the issue on top and saves nothing
    /// (B-18). An activity also rewrites the history's window (B-42).
    private mutating func show(_ outcome: Result<Part, ProviderIssue>, of kind: PartKind, for id: ProviderID, now: Date) -> [Effect] {
        parts[id, default: ProviderParts()].record(outcome, of: kind, at: now)
        let previous = shown[id]?.snapshot
        var effects: [Effect] = []
        let composed = UsageSnapshot.compose(
            provider: id,
            limits: parts[id]?.limits,
            activity: parts[id]?.activity,
            today: today
        )
        switch composed {
        case .success(let snapshot):
            let merged = previous.map { UsageSnapshot.merge($0, snapshot) } ?? snapshot
            shown[id] = .ready(merged)
            effects.append(.saveSnapshot(merged))
        case .failure(let issue):
            shown[id] = .failing(issue, previous: previous)
        }
        if case .success(.activity(let activity)) = outcome {
            history.record(activity.tokens, for: id, today: today)
            effects.append(.saveHistory(history))
        }
        return effects
    }
}
