import BurnieDomain
import Foundation

/// One opaque job a provider declares: it yields one part, with its own policy. The runtime schedules it without
/// knowing what it reads.
public struct RefreshTask: Sendable {
    /// Unique within its provider, for logs and job keys.
    public let name: String
    public let part: PartKind
    public let policy: RefreshPolicy
    /// Only activity tasks: reports changes that run the task with `.activityChanged`.
    public let watcher: (any ActivityWatcher)?
    /// The full part, or the issue; never throws and never crashes.
    public let run: @Sendable () async -> Result<Part, ProviderIssue>

    public init(
        name: String,
        part: PartKind,
        policy: RefreshPolicy,
        watcher: (any ActivityWatcher)? = nil,
        run: @escaping @Sendable () async -> Result<Part, ProviderIssue>
    ) {
        self.name = name
        self.part = part
        self.policy = policy
        self.watcher = watcher
        self.run = run
    }
}
