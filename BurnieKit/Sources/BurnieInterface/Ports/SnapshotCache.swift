import BurnieDomain
import Foundation

/// The app's own files: the snapshot each provider showed last, and the history. Synchronous, so launch shows the
/// cache in its first frame.
public protocol SnapshotCache: Sendable {
    /// nil when there's none or it doesn't decode, like a snapshot saved in an older shape.
    func snapshot(for provider: ProviderID) -> UsageSnapshot?
    /// A failed save is ignored: the next one retries.
    func save(_ snapshot: UsageSnapshot)
    /// nil when there's none or it doesn't decode.
    func history() -> UsageHistory?
    func save(_ history: UsageHistory)
}
