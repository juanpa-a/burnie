import Foundation

/// A fake's state that tasks share and a test can await: `wait(until:)` returns once the state meets a condition,
/// checked again after every `update`, so tests wait on what happened instead of polling for it.
/// `lock` serializes `state` and `waiters`, so tasks can share it.
final class AwaitableState<State>: @unchecked Sendable {
    private typealias Waiter = (isMet: (State) -> Bool, continuation: CheckedContinuation<Void, Never>)

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

    /// Returns once the state meets `isMet`, at once if it already does.
    func wait(until isMet: @escaping (State) -> Bool) async {
        await withCheckedContinuation { continuation in
            let isMetAlready = lock.withLock {
                guard !isMet(state) else { return true }
                waiters.append((isMet, continuation))
                return false
            }
            if isMetAlready {
                continuation.resume()
            }
        }
    }
}
