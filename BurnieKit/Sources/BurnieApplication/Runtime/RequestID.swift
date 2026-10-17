import Foundation

/// Identifies one refresh request: a use case call that refreshes and waits for what it started. Drawn by the
/// interpreter when the use case starts.
struct RequestID: Hashable, Sendable {
    let value: Int

    var successor: RequestID {
        RequestID(value: value + 1)
    }
}
