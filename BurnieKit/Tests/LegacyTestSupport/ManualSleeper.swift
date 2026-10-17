import BurnieCore
import Foundation

/// A `Sleeper` whose time only passes when the test says: every sleep waits, with the duration it asked for, until
/// the test resumes it, and a cancelled one throws `CancellationError` at once, as `Task.sleep` does. Tests await
/// the moment sleeps start, which is how they know the work before them is done.
public final class ManualSleeper: Sleeper {
    private struct Sleep {
        let id: UUID
        let duration: TimeInterval
        let continuation: CheckedContinuation<Void, Error>
    }

    private struct State {
        /// Every sleep that started, cancelled or not, in order.
        var started: [TimeInterval] = []
        /// How many of `started` an earlier `nextSleeps` already returned.
        var returned = 0
        var waiting: [Sleep] = []
    }

    private let state = AwaitableState(State())

    public init() {}

    /// The durations of the sleeps still waiting, in the order they started.
    public var pending: [TimeInterval] {
        state.read { $0.waiting.map(\.duration) }
    }

    public func sleep(for seconds: TimeInterval) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Cancellation is checked under the lock that registers the sleep, so either `onCancel` finds the
                // sleep waiting or this check sees the cancellation.
                let isCancelled = state.update { state in
                    state.started.append(seconds)
                    guard !Task.isCancelled else { return true }
                    state.waiting.append(Sleep(id: id, duration: seconds, continuation: continuation))
                    return false
                }
                if isCancelled {
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            takeWaiting { $0.id == id }.forEach { $0.resume(throwing: CancellationError()) }
        }
    }

    /// Waits for the next `count` sleeps to start, counting on from the ones an earlier call returned, and returns
    /// their durations in the order they started.
    @discardableResult
    public func nextSleeps(_ count: Int) async -> [TimeInterval] {
        let range = state.update { state in
            defer { state.returned += count }
            return state.returned..<state.returned + count
        }
        await state.wait { $0.started.count >= range.upperBound }
        return state.read { Array($0.started[range]) }
    }

    /// Returns once exactly `count` sleeps are waiting.
    public func waitUntilPending(_ count: Int) async {
        await state.wait { $0.waiting.count == count }
    }

    /// Ends the waiting sleeps whose duration `matches`, as if their time had come.
    public func resume(where matches: (TimeInterval) -> Bool) {
        takeWaiting { matches($0.duration) }.forEach { $0.resume() }
    }

    /// Removes the waiting sleeps that match and hands back their continuations, to resume outside the lock.
    private func takeWaiting(where matches: (Sleep) -> Bool) -> [CheckedContinuation<Void, Error>] {
        state.update { state in
            let taken = state.waiting.filter(matches)
            state.waiting.removeAll(where: matches)
            return taken.map(\.continuation)
        }
    }
}
