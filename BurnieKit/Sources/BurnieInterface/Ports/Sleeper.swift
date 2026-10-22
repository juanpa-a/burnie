import Foundation

/// The only way the runtime waits, so tests resume waits by hand instead of sleeping.
public protocol Sleeper: Sendable {
    /// Returns once `seconds` have passed; throws `CancellationError` if the waiting task is cancelled first.
    func sleep(for seconds: TimeInterval) async throws
}
