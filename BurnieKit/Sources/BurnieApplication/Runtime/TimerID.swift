import Foundation

/// Identifies one armed timer of a job. Drawn from a counter and never reused, so a `timerFired` already on its way
/// when its timer was cancelled or replaced is recognized and dropped.
struct TimerID: Hashable, Sendable {
    let value: Int

    var successor: TimerID {
        TimerID(value: value + 1)
    }
}
