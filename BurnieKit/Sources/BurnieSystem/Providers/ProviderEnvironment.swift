import Foundation
import BurnieCore

/// What every provider takes from the system.
public struct ProviderEnvironment: Sendable {
    public let home: URL
    /// The macOS user, the account of Claude Code's Keychain item.
    public let userName: String
    public let userAgent: String
    public let store: SnapshotStore
    public let clock: Clock

    public init(home: URL, userName: String, userAgent: String, store: SnapshotStore, clock: Clock) {
        self.home = home
        self.userName = userName
        self.userAgent = userAgent
        self.store = store
        self.clock = clock
    }

    public static func live(appVersion: String, store: SnapshotStore) -> ProviderEnvironment {
        ProviderEnvironment(
            home: FileManager.default.homeDirectoryForCurrentUser,
            userName: NSUserName(),
            userAgent: "Burnie/\(appVersion)",
            store: store,
            clock: SystemClock()
        )
    }
}
