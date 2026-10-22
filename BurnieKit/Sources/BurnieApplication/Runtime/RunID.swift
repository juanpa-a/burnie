import Foundation

/// Identifies one run of a job. Drawn from a counter and never reused, so the outcome of a run that no longer counts is
/// recognized and dropped (B-51).
struct RunID: Hashable, Sendable {
    let value: Int

    var successor: RunID {
        RunID(value: value + 1)
    }
}
