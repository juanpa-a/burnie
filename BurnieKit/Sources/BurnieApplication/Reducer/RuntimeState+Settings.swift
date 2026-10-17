import BurnieDomain
import BurnieInterface
import Foundation

extension RuntimeState {
    /// Tracks or stops tracking a provider; a provider the registry doesn't know, or already in that state, is ignored.
    /// Turning one on starts its watcher and runs its jobs at once; turning it off stops its watcher and timers and
    /// keeps its cache and history (B-37, B-51).
    mutating func toggle(_ id: ProviderID, isOn: Bool, now: Date) -> [Effect] {
        guard let provider = provider(id), settings.enabled.contains(id) != isOn else { return [] }
        if isOn {
            settings.enabled.insert(id)
            addJobs(of: provider)
            return [.saveSetting(.enabled(settings.enabled)), .startWatcher(id)]
                + startRuns(of: provider.jobKeys, for: .manual, now: now)
        }
        settings.enabled.remove(id)
        let removed = removeJobs(of: provider)
        return [.saveSetting(.enabled(settings.enabled)), .stopWatcher(id)] + removed.map(Effect.cancelTimer)
    }

    /// The heart: one favorite at a time, never one that's off (B-52).
    mutating func tapFavorite(_ id: ProviderID) -> [Effect] {
        settings.favorite = Favorite.toggling(id, stored: settings.favorite, enabled: settings.enabled)
        return [.saveSetting(.favorite(settings.favorite))]
    }

    mutating func showRing(_ isShown: Bool) -> [Effect] {
        settings.showRing = isShown
        return [.saveSetting(.ringShown(isShown))]
    }

    mutating func showWeekChart(_ isShown: Bool) -> [Effect] {
        settings.showWeekChart = isShown
        return [.saveSetting(.weekChartShown(isShown))]
    }

    /// A feature switch (B-40).
    mutating func show(_ toggle: FeatureToggle, _ isShown: Bool) -> [Effect] {
        if isShown {
            settings.hiddenFeatures.remove(toggle)
        } else {
            settings.hiddenFeatures.insert(toggle)
        }
        return [.saveSetting(.featureShown(toggle, isShown))]
    }
}
