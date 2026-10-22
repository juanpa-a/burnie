import BurnieInterface
import Foundation

/// A `ProcessRunner` that exits with the status the test sets and remembers what it was asked to run, and the
/// allowlist it was built with. `gate` holds a run while the test keeps it closed, as the provider's app would while it
/// renews.
/// `lock` serializes `status` and `runs`, so tasks can share it.
public final class FakeProcessRunner: ProcessRunner, @unchecked Sendable {
    public struct Run: Equatable, Sendable {
        public let executable: URL
        public let arguments: [String]

        public init(executable: URL, arguments: [String]) {
            self.executable = executable
            self.arguments = arguments
        }
    }

    public let allowedExecutables: [URL]
    public let gate = Gate()
    private let lock = NSLock()
    private var status: Int32?
    private var started: [Run] = []

    /// Every run so far, in order.
    public var runs: [Run] { lock.withLock { started } }

    public init(allowedExecutables: [URL] = [], status: Int32? = 0) {
        self.allowedExecutables = allowedExecutables
        self.status = status
    }

    /// The exit status of the next runs; nil as if the executable couldn't start.
    public func exit(with status: Int32?) {
        lock.withLock { self.status = status }
    }

    public func run(_ executable: URL, arguments: [String]) async -> Int32? {
        await gate.pass()
        return lock.withLock {
            started.append(Run(executable: executable, arguments: arguments))
            return status
        }
    }
}
