import BurnieDomain
import Foundation

extension RuntimeState {
    /// Starts a run of each job, in order, that `trigger` lets run, adding each run to `request` if there is one.
    mutating func startRuns(of keys: [JobKey], for trigger: RefreshTrigger, request: RequestID? = nil, now: Date) -> [Effect] {
        keys.flatMap { startRun(of: $0, for: trigger, request: request, now: now) }
    }

    /// Start a run (SPEC 7.3): if `trigger` lets the job run, take the next run id, mark the job as running in this same
    /// step, so two triggers in a row can't start it twice (B-32), add the run to `request`, drop the timer, and ask
    /// for the run. The timer is cancelled, never the run (B-36).
    mutating func startRun(of key: JobKey, for trigger: RefreshTrigger, request: RequestID?, now: Date) -> [Effect] {
        guard let job = jobs[key], Scheduling.canRun(job, trigger: trigger, isOnline: isOnline, now: now) else { return [] }
        let run = nextRun
        nextRun = run.successor
        jobs[key]?.running = run
        jobs[key]?.timer = nil
        if let request {
            requests[request]?.runs.insert(run)
        }
        return [.cancelTimer(key), .runTask(key, run)]
    }

    /// Arm the timer (SPEC 7.3): take the next timer id and ask for a wait of the job's delay, which replaces any live
    /// timer of the job (B-35). A job whose breaker is tripped gets none: only Refresh runs it (B-81).
    mutating func armTimer(of key: JobKey, jitter: Double, now: Date) -> [Effect] {
        guard let job = jobs[key], !job.breaker.isTripped else { return [] }
        let timer = nextTimer
        nextTimer = timer.successor
        jobs[key]?.timer = timer
        return [.scheduleTimer(key, timer, after: Scheduling.delay(for: job, now: now, jitter: jitter))]
    }

    /// One job per task of `provider`, with nothing run yet (B-37).
    mutating func addJobs(of provider: RegisteredProvider) {
        for task in provider.tasks {
            jobs[JobKey(provider: provider.id, task: task.name)] = JobState(part: task.part, policy: task.policy)
        }
    }

    /// Forgets `provider`'s jobs, so a run of theirs still in flight no longer counts (B-51), and returns their keys.
    mutating func removeJobs(of provider: RegisteredProvider) -> [JobKey] {
        provider.jobKeys.filter { jobs.removeValue(forKey: $0) != nil }
    }

    /// The enabled jobs of `provider` that yield `part`.
    func enabledJobKeys(of provider: ProviderID, yielding part: PartKind) -> [JobKey] {
        enabledJobKeys.filter { $0.provider == provider && jobs[$0]?.part == part }
    }

    // MARK: Requests

    /// Opens `request`: the runs a trigger starts for it join it.
    mutating func open(_ request: RequestID, isRenewing: Bool = false) {
        requests[request] = PendingRequest(isRenewing: isRenewing)
    }

    /// Closes `request` once it has nothing left to wait for, handing its result to whoever awaits it.
    mutating func closeIfDone(_ request: RequestID) -> [Effect] {
        guard let pending = requests[request], pending.isDone else { return [] }
        requests[request] = nil
        return [.finishRequest(request, result: pending.result)]
    }

    /// Takes `run` off every request that waits for it and closes those it was the last of.
    mutating func release(_ run: RunID) -> [Effect] {
        let waiting = requests.filter { $0.value.runs.contains(run) }.keys.sorted { $0.value < $1.value }
        return waiting.flatMap { request in
            requests[request]?.runs.remove(run)
            return closeIfDone(request)
        }
    }
}
