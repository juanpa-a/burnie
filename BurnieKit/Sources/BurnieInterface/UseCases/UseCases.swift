import Foundation

/// Everything the user can do, one use case per field, so previews and tests replace them with no-ops or recorders.
public struct UseCases: Sendable {
    /// Every use case doing nothing; renewing a sign-in reports that it couldn't.
    public static let noop = UseCases(
        openPopover: OpenPopover {},
        refreshUsage: RefreshUsage {},
        renewSignIn: RenewSignIn { _ in false },
        setProviderEnabled: SetProviderEnabled { _, _ in },
        toggleFavorite: ToggleFavorite { _ in },
        setRingShown: SetRingShown { _ in },
        setWeekChartShown: SetWeekChartShown { _ in },
        setFeatureShown: SetFeatureShown { _, _ in },
        setLaunchAtLogin: SetLaunchAtLogin { _ in },
        readLaunchAtLogin: ReadLaunchAtLogin {},
        installUpdate: InstallUpdate {},
        checkUpdates: CheckUpdates {},
        openDashboard: OpenDashboard { _ in },
        quit: Quit {}
    )

    public let openPopover: OpenPopover
    public let refreshUsage: RefreshUsage
    public let renewSignIn: RenewSignIn
    public let setProviderEnabled: SetProviderEnabled
    public let toggleFavorite: ToggleFavorite
    public let setRingShown: SetRingShown
    public let setWeekChartShown: SetWeekChartShown
    public let setFeatureShown: SetFeatureShown
    public let setLaunchAtLogin: SetLaunchAtLogin
    public let readLaunchAtLogin: ReadLaunchAtLogin
    public let installUpdate: InstallUpdate
    public let checkUpdates: CheckUpdates
    public let openDashboard: OpenDashboard
    public let quit: Quit

    public init(
        openPopover: OpenPopover,
        refreshUsage: RefreshUsage,
        renewSignIn: RenewSignIn,
        setProviderEnabled: SetProviderEnabled,
        toggleFavorite: ToggleFavorite,
        setRingShown: SetRingShown,
        setWeekChartShown: SetWeekChartShown,
        setFeatureShown: SetFeatureShown,
        setLaunchAtLogin: SetLaunchAtLogin,
        readLaunchAtLogin: ReadLaunchAtLogin,
        installUpdate: InstallUpdate,
        checkUpdates: CheckUpdates,
        openDashboard: OpenDashboard,
        quit: Quit
    ) {
        self.openPopover = openPopover
        self.refreshUsage = refreshUsage
        self.renewSignIn = renewSignIn
        self.setProviderEnabled = setProviderEnabled
        self.toggleFavorite = toggleFavorite
        self.setRingShown = setRingShown
        self.setWeekChartShown = setWeekChartShown
        self.setFeatureShown = setFeatureShown
        self.setLaunchAtLogin = setLaunchAtLogin
        self.readLaunchAtLogin = readLaunchAtLogin
        self.installUpdate = installUpdate
        self.checkUpdates = checkUpdates
        self.openDashboard = openDashboard
        self.quit = quit
    }
}
