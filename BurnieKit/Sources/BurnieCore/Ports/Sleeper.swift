import Foundation

/// How the refresh runtime waits: refresh timers and the wake delay sleep through it, so tests resume them by hand.
public protocol Sleeper: Sendable {
    /// Returns once `seconds` have passed; throws if the waiting task is cancelled first.
    func sleep(for seconds: TimeInterval) async throws
}
