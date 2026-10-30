import BurnieInterface
import Foundation

extension UseCases {
    /// Every use case as an event for the runtime; those that wait return once what they started finished.
    @MainActor
    static func live(_ interpreter: Interpreter) -> UseCases {
        UseCases(
            openPopover: OpenPopover { [weak interpreter] in interpreter?.send { .popoverOpened($0) } },
            refreshUsage: RefreshUsage { [weak interpreter] in _ = await interpreter?.request { .refreshRequested($0) } },
            renewSignIn: RenewSignIn { [weak interpreter] id in await interpreter?.request { .renewRequested(id, $0) } ?? false },
            setProviderEnabled: SetProviderEnabled { [weak interpreter] id, isOn in interpreter?.deliver(.providerToggled(id, isOn: isOn)) },
            toggleFavorite: ToggleFavorite { [weak interpreter] id in interpreter?.deliver(.favoriteTapped(id)) },
            setRingShown: SetRingShown { [weak interpreter] isShown in interpreter?.deliver(.ringShownSet(isShown)) },
            setWeekChartShown: SetWeekChartShown { [weak interpreter] isShown in interpreter?.deliver(.weekChartShownSet(isShown)) },
            setFeatureShown: SetFeatureShown { [weak interpreter] toggle, isShown in interpreter?.deliver(.featureShownSet(toggle, isShown)) },
            setLaunchAtLogin: SetLaunchAtLogin { [weak interpreter] isEnabled in interpreter?.deliver(.launchAtLoginSet(isEnabled)) },
            readLaunchAtLogin: ReadLaunchAtLogin { [weak interpreter] in interpreter?.deliver(.launchAtLoginReadRequested) },
            installUpdate: InstallUpdate { [weak interpreter] in interpreter?.deliver(.installUpdateRequested) },
            checkUpdates: CheckUpdates { [weak interpreter] in interpreter?.deliver(.checkUpdatesRequested) },
            openDashboard: OpenDashboard { [weak interpreter] id in interpreter?.deliver(.dashboardRequested(id)) },
            quit: Quit { [weak interpreter] in interpreter?.deliver(.quitRequested) }
        )
    }
}
