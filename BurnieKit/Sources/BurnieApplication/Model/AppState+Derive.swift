import BurnieDomain
import BurnieInterface
import Foundation

extension AppState {
    /// What the views render, as a pure function of the runtime state (A-6). Its only links to time are `today`, the
    /// latest event's day, where the week chart ends, and that event's time zone, where each cycle's first day lies.
    static func derive(from state: RuntimeState) -> AppState {
        let settings = state.settings
        let enabled = state.registry.filter { settings.enabled.contains($0.id) }
        let favorite = Favorite.effective(stored: settings.favorite, enabled: settings.enabled)
        let snapshots = enabled.compactMap { state.shown[$0.id]?.snapshot }
        let enabledIDs = enabled.map(\.id)
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
                ? WeekChart.make(
                    history: state.history,
                    providers: enabledIDs,
                    today: state.today,
                    cycleStarts: cycleStarts(of: enabledIDs, in: state)
                )
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

    /// The local day each provider's cycle starts on, from the meters of its shown snapshot (B-79).
    private static func cycleStarts(of providers: [ProviderID], in state: RuntimeState) -> [ProviderID: LocalDay] {
        let startByProvider = providers.compactMap { id -> (ProviderID, LocalDay)? in
            guard let cycle = state.shown[id]?.snapshot?.meters?.cycle else { return nil }
            return (id, LocalDay(cycle.start, in: state.timeZone))
        }
        return Dictionary(startByProvider, uniquingKeysWith: { first, _ in first })
    }
}
