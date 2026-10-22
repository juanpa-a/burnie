import BurnieDomain
import BurnieInterface
import Foundation

extension AppState {
    /// What the views render, as a pure function of the runtime state (A-6). Its only link to time is `today`, the
    /// latest event's day, where the week chart ends.
    static func derive(from state: RuntimeState) -> AppState {
        let settings = state.settings
        let enabled = state.registry.filter { settings.enabled.contains($0.id) }
        let favorite = Favorite.effective(stored: settings.favorite, enabled: settings.enabled)
        let snapshots = enabled.compactMap { state.shown[$0.id]?.snapshot }
        return AppState(
            providers: state.registry.map { provider in
                ProviderPanel(
                    descriptor: provider.descriptor,
                    isEnabled: settings.enabled.contains(provider.id),
                    isFavorite: provider.id == favorite,
                    state: (state.shown[provider.id] ?? .loading).hiding(settings.hiddenFeatures),
                    renewalFailedCopy: provider.renewalFailedCopy,
                    sourceLocation: provider.sourceLocation
                )
            },
            ring: Favorite.ring(stored: settings.favorite, enabled: settings.enabled, showRing: settings.showRing, states: state.shown),
            weekChart: settings.showWeekChart && !enabled.isEmpty
                ? WeekChart.make(history: state.history, providers: enabled.map(\.id), today: state.today)
                : nil,
            lastUpdated: snapshots.map(\.fetchedAt).max(),
            isRefreshing: !state.requests.isEmpty,
            settings: settings,
            // Judged before hiding, so turning a feature off keeps its switch (B-40).
            visibleToggles: FeatureToggle.allCases.filter { toggle in snapshots.contains { $0.features.has(toggle) } },
            launchAtLogin: state.launchAtLogin,
            availableUpdate: state.availableUpdate
        )
    }
}
