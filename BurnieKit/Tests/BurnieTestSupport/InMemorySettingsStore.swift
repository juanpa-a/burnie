import BurnieDomain
import BurnieInterface
import Foundation

/// A `SettingsStore` kept in memory that remembers each change saved, in order.
/// `lock` serializes the state, so tasks can share it.
public final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    private let lock = NSLock()
    private let saved: AppSettings?
    private var changes: [SettingChange] = []

    /// Every change saved so far, in order.
    public var saves: [SettingChange] { lock.withLock { changes } }

    /// `saved` is what the next launch loads; without it, the defaults of a first launch.
    public init(saved: AppSettings? = nil) {
        self.saved = saved
    }

    public func load(defaultEnabled: Set<ProviderID>) -> AppSettings {
        saved ?? .defaults(enabled: defaultEnabled)
    }

    public func save(_ change: SettingChange) {
        lock.withLock { changes.append(change) }
    }
}
