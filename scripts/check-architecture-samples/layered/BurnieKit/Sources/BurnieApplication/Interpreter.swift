// expect: A-5
import BurnieInterface

/// Waits for the next timer with Task.sleep instead of the Sleeper port.
struct Interpreter {
    func waitForTimer() async throws {
        try await Task.sleep(for: .seconds(60))
    }
}
