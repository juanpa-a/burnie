import Foundation
import BurnieCore

/// A provider ready for the store, with what the wiring needs besides the port.
public struct ProviderAssembly: Sendable {
    public let provider: any UsageProvider
    /// Reports when local activity changes; nil if activity can only be fetched over the network.
    public let watcher: (any ActivityWatcher)?
    /// Where it reads from, for the providers screen ("~/.claude"); nil if not applicable.
    public let sourceLocation: String?

    public init(provider: any UsageProvider, watcher: (any ActivityWatcher)? = nil, sourceLocation: String? = nil) {
        self.provider = provider
        self.watcher = watcher
        self.sourceLocation = sourceLocation
    }

    public var id: ProviderID {
        provider.id
    }
}
