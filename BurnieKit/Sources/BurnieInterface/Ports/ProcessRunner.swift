import Foundation

/// Runs an executable from the allowlist it was built with, with a clean environment, no output and a timeout.
public protocol ProcessRunner: Sendable {
    /// The exit status, or nil when `executable` isn't allowed or couldn't start. A run past the timeout is stopped
    /// and exits with a failure status (B-71).
    func run(_ executable: URL, arguments: [String]) async -> Int32?
}
