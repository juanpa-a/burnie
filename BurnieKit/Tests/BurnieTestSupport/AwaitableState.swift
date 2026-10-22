import Foundation

/// A fake's state that tasks share and a test can await: `wait(until:)` returns once the state meets a condition,
/// checked again after every `update`, so tests wait on what happened instead of polling for it. A cancelled wait, like
/// one a test's time limit ends, returns at once, so a lost signal fails the test instead of hanging the run.
/// `lock` serializes `state` and `waiters`, so tasks can share it.
final class AwaitableState<State>: @unchecked Sendable {
    private typealias Waiter = (id: UUID, isMet: (State) -> Bool, continuation: CheckedContinuation<Void, Never>)

    private let lock = NSLock()
    private var state: State
    private var waiters: [Waiter] = []

    init(_ state: State) {
        self.state = state
    }

    func read<Value>(_ body: (State) -> Value) -> Value {
        lock.withLock { body(state) }
    }

    /// Changes the state, then resumes the waiters whose condition it now meets.
    @discardableResult
    func update<Value>(_ change: (inout State) -> Value) -> Value {
        let (value, met) = lock.withLock {
            let value = change(&state)
            let met = waiters.filter { $0.isMet(state) }
            waiters.removeAll { $0.isMet(state) }
            return (value, met)
        }
        met.forEach { $0.continuation.resume() }
        return value
    }

    /// Returns once the state meets `isMet`, at once if it already does, or once the waiting task is cancelled.
    func wait(until isMet: @escaping (State) -> Bool) async {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                // Cancellation is checked under the lock that registers the waiter, so either `onCancel` finds it
                // waiting or this check sees the cancellation.
                let returnsAtOnce = lock.withLock {
                    guard !isMet(state), !Task.isCancelled else { return true }
                    waiters.append((id, isMet, continuation))
                    return false
                }
                if returnsAtOnce {
                    continuation.resume()
                }
            }
        } onCancel: {
            let cancelled = lock.withLock {
                defer { waiters.removeAll { $0.id == id } }
                return waiters.filter { $0.id == id }
            }
            cancelled.forEach { $0.continuation.resume() }
        }
    }
}
