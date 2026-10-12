import Foundation
import os
import BurnieCore
import BurnieSystem

extension UsageStore {
    /// The real app: providers with system adapters and the cache in `Application Support/Burnie/`.
    static func live() -> UsageStore {
        let cache: SnapshotStore
        do {
            cache = try JSONFileStore.applicationSupport()
        } catch {
            Logger(subsystem: "dev.juanpa.burnie", category: "store").error("No Application Support folder: \(error.localizedDescription, privacy: .public)")
            cache = JSONFileStore(directory: FileManager.default.temporaryDirectory.appending(path: "Burnie"))
        }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let environment = ProviderEnvironment.live(appVersion: version, store: cache)
        let store = UsageStore(
            providers: [ClaudeProvider.assemble(in: environment), CursorProvider.assemble(in: environment)],
            cache: cache,
            clock: environment.clock,
            enabledSetting: .enabledProviders(),
            favoriteSetting: .favoriteProvider(),
            showRingSetting: .showRing(),
            showWeekChartSetting: .showWeekChart()
        )
        store.start()
        return store
    }
}
