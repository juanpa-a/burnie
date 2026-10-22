import BurnieDomain
import Foundation

/// What the runtime knows about one job: its part kind and policy, the run in flight, the armed timer, when it last
/// ran, its backoff and its idle backoff.
struct JobState: Equatable, Sendable {
    let part: PartKind
    let policy: RefreshPolicy
    /// Single flight (B-32): set in the same step that asks for the run.
    var running: RunID?
    /// The armed timer; nil once it fired or was cancelled.
    var timer: TimerID?
    var lastRun: Date?
    var backoff = RateLimitBackoff()
    var idle = IdleBackoff()

    init(part: PartKind, policy: RefreshPolicy) {
        self.part = part
        self.policy = policy
    }
}
