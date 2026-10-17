import BurnieInterface
import Foundation

/// What the composition root hands the runtime: every port it uses and the provider bundles, in display order.
@MainActor
public struct AppEnvironment {
    let clock: any Clock
    let sleeper: any Sleeper
    let snapshotCache: any SnapshotCache
    let settingsStore: any SettingsStore
    let systemEvents: any SystemEvents
    let loginItem: any LoginItem
    let updater: any Updater
    let urlOpener: any URLOpener
    let lifecycle: any AppLifecycle
    let providers: [ProviderBundle]
    /// A sample in -1…1 for each timer's jitter.
    let jitter: @Sendable () -> Double

    public init(
        clock: any Clock,
        sleeper: any Sleeper,
        snapshotCache: any SnapshotCache,
        settingsStore: any SettingsStore,
        systemEvents: any SystemEvents,
        loginItem: any LoginItem,
        updater: any Updater,
        urlOpener: any URLOpener,
        lifecycle: any AppLifecycle,
        providers: [ProviderBundle],
        jitter: @escaping @Sendable () -> Double = { Double.random(in: -1...1) }
    ) {
        self.clock = clock
        self.sleeper = sleeper
        self.snapshotCache = snapshotCache
        self.settingsStore = settingsStore
        self.systemEvents = systemEvents
        self.loginItem = loginItem
        self.updater = updater
        self.urlOpener = urlOpener
        self.lifecycle = lifecycle
        self.providers = providers
        self.jitter = jitter
    }
}
