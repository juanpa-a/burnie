// expect: A-5
import Foundation

/// Waits out a Retry-After on its own.
enum RetryWait {
    static func pause(seconds: Int) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }
}
