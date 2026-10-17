// expect: none
import Foundation

/// Runs the refresh jobs. Actors, async, Task.sleep and public types are still fine in BurnieCore:
/// D-2, A-1 and A-5 wake with the new modules.
public actor RefreshLoop {
    public var status = "Updating"

    public func run(every interval: Duration) async throws {
        try await Task.sleep(for: interval)
    }
}
