import BurnieInterface
import Foundation

/// What a provider asked its port factories for: the hosts of its HTTP client, the directories of its watcher and the
/// executables of its process runner. Hands back the fakes the test reads.
/// `lock` serializes the recorded requests, so tasks can share it.
public final class ProviderPortsRecorder: @unchecked Sendable {
    public let http: FakeHTTPClient
    public let watcher = FakeActivityWatcher()
    public let runner: FakeProcessRunner
    private let lock = NSLock()
    private var hosts: [Set<String>] = []
    private var directories: [[URL]] = []
    private var executables: [[URL]] = []

    public var requestedHosts: [Set<String>] { lock.withLock { hosts } }
    public var watchedDirectories: [[URL]] { lock.withLock { directories } }
    public var allowedExecutables: [[URL]] { lock.withLock { executables } }

    public init(http: FakeHTTPClient = FakeHTTPClient(), runner: FakeProcessRunner = FakeProcessRunner()) {
        self.http = http
        self.runner = runner
    }

    public func makeHTTPClient(_ allowedHosts: Set<String>) -> any HTTPClient {
        lock.withLock { hosts.append(allowedHosts) }
        return http
    }

    public func makeWatcher(_ watched: [URL]) -> any ActivityWatcher {
        lock.withLock { directories.append(watched) }
        return watcher
    }

    public func makeProcessRunner(_ allowed: [URL]) -> any ProcessRunner {
        lock.withLock { executables.append(allowed) }
        return runner
    }
}
