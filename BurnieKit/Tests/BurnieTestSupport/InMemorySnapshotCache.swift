import BurnieDomain
import BurnieInterface
import Foundation

/// A `SnapshotCache` kept in memory that remembers every save, so tests see what was persisted and when.
/// `lock` serializes the state, so tasks can share it.
public final class InMemorySnapshotCache: SnapshotCache, @unchecked Sendable {
    private let lock = NSLock()
    private var snapshots: [ProviderID: UsageSnapshot] = [:]
    private var savedHistory: UsageHistory?
    private var snapshotSaves = 0
    private var historySaves = 0

    public var savedSnapshots: Int { lock.withLock { snapshotSaves } }
    public var savedHistories: Int { lock.withLock { historySaves } }

    public init(snapshots: [ProviderID: UsageSnapshot] = [:], history: UsageHistory? = nil) {
        self.snapshots = snapshots
        savedHistory = history
    }

    public func snapshot(for provider: ProviderID) -> UsageSnapshot? {
        lock.withLock { snapshots[provider] }
    }

    public func save(_ snapshot: UsageSnapshot) {
        lock.withLock {
            snapshots[snapshot.provider] = snapshot
            snapshotSaves += 1
        }
    }

    public func history() -> UsageHistory? {
        lock.withLock { savedHistory }
    }

    public func save(_ history: UsageHistory) {
        lock.withLock {
            savedHistory = history
            historySaves += 1
        }
    }
}
