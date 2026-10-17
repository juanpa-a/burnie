import BurnieInterface
import Foundation

/// `Sleeper` over `Task.sleep`, which throws `CancellationError` when the waiting task is cancelled.
public struct TaskSleeper: Sleeper {
    public init() {}

    public func sleep(for seconds: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }
}
