import BurnieDomain
import Foundation

extension RuntimeState {
    /// What was saved arrives: the settings, without providers the registry doesn't know (they're dropped on the next
    /// save of their key, SPEC section 12), each provider's cached snapshot, else loading, and the history. Then
    /// everything starts: system events, the updater, each enabled provider's watcher, and a run of every job (B-37,
    /// B-50).
    mutating func launch(settings: AppSettings, cached: [ProviderID: UsageSnapshot], history: UsageHistory, now: Date) -> [Effect] {
        self.settings = settings
        self.settings.enabled.formIntersection(registry.map(\.id))
        self.history = history
        for provider in registry {
            shown[provider.id] = cached[provider.id].map(ProviderState.ready) ?? .loading
        }
        let enabled = registry.filter { self.settings.enabled.contains($0.id) }
        enabled.forEach { addJobs(of: $0) }
        return [.startSystemEvents, .startUpdater]
            + enabled.map { .startWatcher($0.id) }
            + startRuns(of: enabledJobKeys, for: .manual, now: now)
    }
}
