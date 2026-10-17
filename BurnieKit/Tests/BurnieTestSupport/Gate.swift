import Foundation

/// Where a fake's calls pass through, so a test can hold them in flight and know when they arrive. Open until the test
/// closes it, so a fake with a gate behaves as if it had none for every test that never touches it.
public final class Gate: Sendable {
    private struct State {
        var isOpen = true
        var arrivals = 0
        var held: [CheckedContinuation<Void, Never>] = []
    }

    private let state = AwaitableState(State())

    public init() {}

    /// From now on, calls wait at the gate until `open()`.
    public func close() {
        state.update { $0.isOpen = false }
    }

    /// Lets the held calls through, and every later one until the next `close()`.
    public func open() {
        let released = state.update { state in
            state.isOpen = true
            defer { state.held = [] }
            return state.held
        }
        released.forEach { $0.resume() }
    }

    /// A fake calls it first thing on each call: the call counts as arrived and, while the gate is closed, waits.
    public func pass() async {
        await withCheckedContinuation { continuation in
            let isOpen = state.update { state in
                state.arrivals += 1
                if !state.isOpen {
                    state.held.append(continuation)
                }
                return state.isOpen
            }
            if isOpen {
                continuation.resume()
            }
        }
    }

    /// Returns once `count` calls have arrived since the gate was made, held or not.
    public func waitForArrivals(_ count: Int) async {
        await state.wait { $0.arrivals >= count }
    }
}
